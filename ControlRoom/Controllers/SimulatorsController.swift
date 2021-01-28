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

        /// Invalid command line tool
        case invalidCommandLineTool
    }

    /// The current loading state; defaults to .loading
    @Published var loadingStatus: LoadingStatus = .loading

    /// An array of all simulators that match the user's current filter.
    @Published var simulators = [Simulator]()

    /// An array of all the applications installed on the selected simulator.
    @Published var applications = [Application]()

    /// An array of all simulators that were loaded from simctl.
    private var allSimulators = [Simulator]()

    private(set) var deviceTypes = [DeviceType]()
    private(set) var runtimes = [Runtime]()

    /// The simulators the user has selected to work with. If this has one item then
    /// they are working with a simulator; if more than one they are probably about
    /// to delete several at a time.
    var selectedSimulatorIDs = Set<String>() {
        willSet { objectWillChange.send() }
        didSet { loadApplications() }
    }

    var selectedSimulators: [Simulator] {
        var selected = [Simulator]()
        if selectedSimulatorIDs.contains(Simulator.default.udid) {
            selected.append(Simulator.default)
        }
        selected.append(contentsOf: allSimulators.filter { selectedSimulatorIDs.contains($0.udid) })
        return selected
    }

    @ObservedObject var preferences: Preferences
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences) {
        self.preferences = preferences

        XcodeCommandLineToolsController.selectedCommandLineTool()
            .receive(on: DispatchQueue.main)
            .sink { tool in
                if tool != .empty {
                    self.loadSimulators()
                } else {
                    self.loadingStatus = .invalidCommandLineTool
                }
            }
            .store(in: &cancellables)

        preferences.objectDidChange
            .sink { [weak self] in
                self?.filterSimulators()
            }
            .store(in: &cancellables)
    }

    /// Fetches all simulators from simctl.
    private func loadSimulators() {
        loadingStatus = .loading

        let devices = SimCtl.watchDeviceList()
        let deviceTypes = SimCtl.listDeviceTypes()
        let runtimes = SimCtl.listRuntimes()

        devices.combineLatest(deviceTypes, runtimes)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: finishedLoadingSimulators,
                  receiveValue: handleLoadedInformation)
            .store(in: &cancellables)
    }

    private func handleLoadedInformation(_ deviceList: SimCtl.DeviceList,
                                         _ deviceTypes: SimCtl.DeviceTypeList,
                                         _ runtimes: SimCtl.RuntimeList) {
        var final = [Simulator]()

        let lookupDeviceType = Dictionary(grouping: deviceTypes.devicetypes, by: \.identifier).compactMapValues(\.first)
        let lookupRuntime = Dictionary(grouping: runtimes.runtimes, by: \.identifier).compactMapValues(\.first)

        for (runtimeIdentifier, devices) in deviceList.devices {
            let runtime: SimCtl.Runtime?

            if let known = lookupRuntime[runtimeIdentifier] {
                runtime = known
            } else if let parsed = SimCtl.Runtime(runtimeIdentifier: runtimeIdentifier) {
                runtime = parsed
            } else {
                runtime = nil
            }

            for device in devices {
                let type = lookupDeviceType[device.deviceTypeIdentifier ?? ""]
                let state = Simulator.State(deviceState: device.state)

                let sim = Simulator(name: device.name,
                                    udid: device.udid,
                                    state: state,
                                    runtime: runtime,
                                    deviceType: type,
                                    dataPath: device.dataPath ?? "")
                final.append(sim)
            }
        }

        objectWillChange.send()
        self.deviceTypes = deviceTypes.devicetypes
        self.runtimes = runtimes.runtimes
        loadingStatus = .success
        allSimulators = final
        filterSimulators()
    }

    private func finishedLoadingSimulators(_ completion: Subscribers.Completion<SimCtl.Error>) {
        objectWillChange.send()

        switch completion {
        case .failure:
            loadingStatus = .failed
        default:
            loadingStatus = .success
        }
    }

    /// Filters the list of simulators using `filterText`, and assigns the result to `simulators`.
    private func filterSimulators() {
        guard loadingStatus == .success else { return }

        let trimmed = preferences.filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        var filtered = allSimulators

        if preferences.showBootedDevicesFirst {
            let on = filtered.filter { $0.state != .shutdown }
            let off = filtered.filter { $0.state == .shutdown }
            filtered = on.sorted() + off.sorted()
        } else {
            filtered = filtered.sorted()
        }

        if preferences.showDefaultSimulator {
            filtered = [.default] + filtered
        }

        if trimmed.isNotEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }

        if preferences.shouldShowOnlyActiveDevices == true {
            filtered = filtered.filter { $0.state != .shutdown }
        }

        simulators = filtered

        let oldSelection = selectedSimulatorIDs
        let selectableIDs = Set(filtered.map(\.udid))
        let newSelection = oldSelection.intersection(selectableIDs)

        selectedSimulatorIDs = newSelection
    }

    private func loadApplications() {
        guard
            let selectedDeviceUDID = selectedSimulatorIDs.first
            else { return }

        SimCtl.listApplications(selectedDeviceUDID)
            .catch { _ in Just(SimCtl.ApplicationsList()) }
            .map { $0.values.compactMap(Application.init) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.applications, on: self)
            .store(in: &cancellables)
    }
}
