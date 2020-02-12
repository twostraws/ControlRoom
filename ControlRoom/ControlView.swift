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
    let simulator: Simulator

    var body: some View {
        VStack {
            HStack {
                Text(simulator.name)
                Spacer()
                Button("Boot", action: bootDevice)
                Button("Shutdown", action: shutdownDevice)
            }
            .padding(.bottom, 10)

            TabView {
                SystemView(simulator: simulator)
                AppView(simulator: simulator)
                BatteryView(simulator: simulator)
                DataView(simulator: simulator)
            }
        }
        .padding()
    }

    /// Launches the current device.
    func bootDevice() {
        Command.simctl("boot", simulator.udid)
    }

    /// Terminates the current device.
    func shutdownDevice() {
        Command.simctl("shutdown", simulator.udid)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(simulator: .example)
    }
}
