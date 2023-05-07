//
//  ControlView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// The main tab view to control simulator settings.
struct ControlView: View {
    @ObservedObject var controller: SimulatorsController

    let simulator: Simulator
    let applications: [Application]

    var body: some View {
        TabView {
            SystemView(simulator: simulator)
            AppView(simulator: simulator, applications: applications)
            BatteryView(simulator: simulator)
            LocationView(controller: controller, simulator: simulator)
            NetworkView(simulator: simulator)
            ScreenView(simulator: simulator)
        }
        .disabled(simulator.state != .booted)
        .navigationSubtitle("\(simulator.name) – \(simulator.runtime?.description ?? "Unknown OS")")
        .toolbar {
            if simulator.state != .booted {
                Button("Boot", action: bootDevice)
            }

            if simulator.state != .shutdown {
                Button("Shutdown", action: shutdownDevice)
            }
        }
    }

    /// Launches the current device.
    func bootDevice() {
        SimCtl.boot(simulator.udid)
    }

    /// Terminates the current device.
    func shutdownDevice() {
        SimCtl.shutdown(simulator.udid)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(controller: .init(preferences: .init()),
                    simulator: .example,
                    applications: [])
            .environmentObject(Preferences())
    }
}
