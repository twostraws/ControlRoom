//
//  MainView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Hosts a LoadingView followed by the main ControlView, or a LoadingFailedView if simctl failed.
struct MainView: View {
    /// Handles decoding the device list from simctl
    private struct DeviceList: Decodable {
        var devices: [String: [Simulator]]
    }

    /// Tracks the state of fetching simulator data from simctl
    private enum LoadingStatus {
        /// Loading is in progress
        case loading

        /// Loading succeeded
        case success

        /// Loading failed
        case failed
    }

    /// The current load state for the app.
    @State private var loadingStatus = LoadingStatus.loading

    /// An array of simulator data sent back from simctl.
    @State private var simulators = [Simulator]()

    var body: some View {
        Group {
            if loadingStatus == .loading {
                LoadingView()
            } else if loadingStatus == .success {
                ControlView(simulators: simulators)
            } else {
                LoadingFailedView()
            }
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        .onAppear(perform: fetchSimulators)
    }

    /// Calls simctl and reads the list of simulators the user has installed.
    private func fetchSimulators() {
        Command.simctl("list", "devices", "available", "-j") { result in
            switch result {
            case .success(let data):
                if let deviceOutput = try? JSONDecoder().decode(DeviceList.self, from: data) {
                    self.simulators = [Simulator.default] + deviceOutput.devices.reduce([]) { $0 + $1.value }.sorted()
                    self.loadingStatus = .success
                } else {
                    self.loadingStatus = .failed
                }
            case .failure:
                self.loadingStatus = .failed
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
