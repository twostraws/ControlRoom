//
//  SimulatorsController.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

extension SimCtl.DeviceList {
    fileprivate var simulators: [SimCtl.Simulator] {
        devices.flatMap { element -> [SimCtl.Simulator] in
            let (key, sims) = element
            return sims.map { SimCtl.Simulator(decoded: $0, runtimeIdentifier: key) }
        }
    }
}

extension SimCtl {
    fileprivate struct Simulator {
        let status: String?
        let isAvailable: Bool
        let name: String
        let udid: String
        let runtimeIdentifier: String
        let deviceTypeIdentifier: String?
        let dataPath: String?

        init(decoded: Device, runtimeIdentifier: String) {
            self.status = decoded.status
            self.isAvailable = decoded.isAvailable
            self.name = decoded.name
            self.udid = decoded.udid
            self.runtimeIdentifier = runtimeIdentifier
            self.dataPath = decoded.dataPath
            self.deviceTypeIdentifier = decoded.deviceTypeIdentifier
        }

        func inferModelTypeIdentifier(using deviceTypes: [String: DeviceType]) -> TypeIdentifier {
            if let typeID = deviceTypeIdentifier, let device = deviceTypes[typeID], let model = device.modelTypeIdentifier {
                return model
            }
            // fall back to inferring the model type from the name
            if name.contains("iPad") { return .defaultiPad }
            if name.contains("Watch") { return .defaultWatch }
            if name.contains("TV") { return .defaultTV }
            return .defaultiPhone
        }
    }
}

/// A centralized class that loads simulator data and handles filtering.
class SimulatorsController: ObservableObject {

    /// Tracks the state of fetching simulator data from simctl.
    enum LoadingStatus {
        /// Loading is in progress
        case loading

        /// Loading succeeded
        case success

        /// Loading failed
        case failed
    }

    /// The current loading state; defaults to .loading
    @Published var loadingStatus: LoadingStatus = .loading

    /// An array of all simulators that match the user's current filter.
    @Published var simulators = [Simulator]()

    /// An array of all simulators that were loaded from simctl.
    private var allSimulators = [Simulator]()

    /// A string that filters the list of available simulators.
    var filterText = "" {
        willSet { objectWillChange.send() }
        didSet { filterSimulators() }
    }

    /// The simulator the user is actively working with.
    var selectedSimulator: Simulator? {
        willSet { objectWillChange.send() }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadSimulators()
    }

    /// Fetches all simulators from simctl.
    private func loadSimulators() {
        loadingStatus = .loading

        let devices = SimCtl.listDevices()
        let deviceTypes = SimCtl.listDeviceTypes()
        let runtimes = SimCtl.listRuntimes()

        let combined = devices.combineLatest(deviceTypes, runtimes)
        combined.sink(receiveCompletion: self.finishedLoadingSimulators,
                      receiveValue: self.handleLoadedInformation)
            .store(in: &cancellables)

        Command.simctl("list", "devices", "available", "-j") { result in
            switch result {
            case .success(let data):
                do {
                    let list = try JSONDecoder().decode(SimCtl.DeviceList.self, from: data)
                    let parsed = list.simulators
                    self.loadDeviceTypes(parsedSimulators: parsed)
                } catch {
                    print(error)
                }
            case .failure:
                self.loadDeviceTypes(parsedSimulators: nil)
            }
        }
    }

    private func handleLoadedInformation(_ deviceList: SimCtl.DeviceList, _ deviceTypes: SimCtl.DeviceTypeList, _ runtimes: SimCtl.RuntimeList) {
        var final = [Simulator]()

        let lookupDeviceType = Dictionary(grouping: deviceTypes.devicetypes, by: { $0.identifier }).compactMapValues({ $0.first })
        let lookupRuntime = Dictionary(grouping: runtimes.runtimes, by: { $0.identifier }).compactMapValues({ $0.first })
        for (deviceType, devices) in deviceList.devices {
            for device in devices {
                let model: TypeIdentifier
                if let deviceType = lookupDeviceType[device.deviceTypeIdentifier ?? ""], let modelType = deviceType.modelTypeIdentifier {
                    model = modelType
                } else if device.name.contains("iPad") {
                    model = .pad
                } else if device.name.contains("Watch") {
                    model = .watch
                } else if device.name.contains("TV") {
                    model = .tv
                } else {
                    model = .defaultiPhone
                }
            }
        }

        self.simulators = final
    }

    private func finishedLoadingSimulators(_ completion: Subscribers.Completion<Command.CommandError>) {

    }

    /// Fetches the kinds of simulators supports by simctl
    private func loadDeviceTypes(parsedSimulators: [SimCtl.Simulator]?) {
        Command.simctl("list", "devicetypes", "-j") { result in
            switch result {
            case .success(let data):
                let list = try? JSONDecoder().decode(SimCtl.DeviceTypeList.self, from: data)
                self.merge(parsedSimulators: parsedSimulators, deviceTypes: list?.devicetypes)
            case .failure:
                self.merge(parsedSimulators: parsedSimulators, deviceTypes: nil)
            }
        }
    }

    /// Merges the known simulators with the simulator definitions
    private func merge(parsedSimulators: [SimCtl.Simulator]?, deviceTypes: [SimCtl.DeviceType]?) {
        let rawTypes = deviceTypes ?? []
        let typesByIdentifier = Dictionary(grouping: rawTypes, by: { $0.identifier }).compactMapValues({ $0.first })

        let merged = parsedSimulators?.map { sim -> Simulator in
            let modelType = sim.inferModelTypeIdentifier(using: typesByIdentifier)
            return Simulator(name: sim.name, udid: sim.udid, typeIdentifier: modelType)
        }

        handleParsedSimulators(merged)
    }

    /// Filters the loaded simulators and updates our UI.
    private func handleParsedSimulators(_ newSimulators: [Simulator]?) {
        objectWillChange.send()

        if let new = newSimulators {
            allSimulators = [.default] + new.sorted()
            filterSimulators()
            loadingStatus = .success
        } else {
            loadingStatus = .failed
        }
    }

    /// Filters the list of simulators using `filterText`, and assigns the result to `simulators`.
    private func filterSimulators() {
        let trimmed = filterText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty == false {
            simulators = allSimulators.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        } else {
            simulators = allSimulators
        }

        if let current = selectedSimulator {
            if simulators.firstIndex(of: current) == nil {
                // the current simulator is not in the list of filtered simulators
                // deselect it
                selectedSimulator = nil
            }
        }

        if selectedSimulator == nil {
            selectedSimulator = simulators.first
        }
    }

}
