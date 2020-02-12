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
    var simulators: [Simulator]

    /// Whichever simulator the user is actively working with.
    @State private var selectedSimulator = 0

    /// Returns the current simulator from the simulators array.
    private var currentSimulator: Simulator {
        self.simulators[self.selectedSimulator]
    }

    var body: some View {
        VStack {
            HStack {
                Picker("Simulator:", selection: $selectedSimulator) {
                    ForEach(0..<simulators.count) { index in
                        Text(self.simulators[index].name)
                    }
                }

                Button("Boot", action: bootDevice)
                Button("Shutdown", action: shutdownDevice)
            }
            .padding(.bottom, 10)

            TabView {
                SystemView(simulator: currentSimulator)
                AppView(simulator: currentSimulator)
                BatteryView(simulator: currentSimulator)
                DataView(simulator: currentSimulator)
            }
        }
        .padding()
    }

    /// Launches the current device.
    func bootDevice() {
        Command.simctl("boot", currentSimulator.udid)
    }

    /// Terminates the current device.
    func shutdownDevice() {
        Command.simctl("shutdown", currentSimulator.udid)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(simulators: [.example])
    }
}
