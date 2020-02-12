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

/// Handles decoding the device list from simctl
private struct DeviceList: Decodable {
    var devices: [String: [Simulator]]
}

class SimulatorsController: ObservableObject {

    /// Tracks the state of fetching simulator data from simctl
    enum LoadingStatus {
        /// Loading is in progress
        case loading

        /// Loading succeeded
        case success

        /// Loading failed
        case failed
    }
    
    private var allSimulators: [Simulator] = []
    
    @Published var loadingStatus: LoadingStatus = .loading
    @Published var simulators: [Simulator] = []
    
    var filterText = "" {
        willSet { objectWillChange.send() }
        didSet { filterSimulators() }
    }
    
    var selectedSimulator: Simulator? {
        willSet { objectWillChange.send() }
    }
    
    init() {
        loadSimulators()
    }
    
    private func loadSimulators() {
        loadingStatus = .loading
        
        Command.simctl("list", "devices", "available", "-j") { result in
            switch result {
            case .success(let data):
                let list = try? JSONDecoder().decode(DeviceList.self, from: data)
                let parsed = list?.devices.values.flatMap { $0 }
                self.handleParsedSimulators(parsed)
            case .failure:
                self.handleParsedSimulators(nil)
            }
        }
    }
    
    private func handleParsedSimulators(_ newSimulators: [Simulator]?) {
        objectWillChange.send()
        
        if let new = newSimulators {
            allSimulators = [.default] + new
            filterSimulators()
            loadingStatus = .success
        } else {
            loadingStatus = .failed
        }
    }
    
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
