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
                Image(nsImage: simulator.image)
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: 64)
                VStack(alignment: .leading) {
                    Text(simulator.name)
                        .font(.title)
                    if simulator.runtime != nil {
                        Text(simulator.runtime!.description)
                    }
                }
                Spacer()
                VStack {
                    if simulator.state != .booted {
                        Button("Boot", action: bootDevice)
                    }
                    if simulator.state != .shutdown {
                        Button("Shutdown", action: shutdownDevice)
                    }
                }
            }
            .padding(.bottom, 10)

            TabView {
                SystemView(simulator: simulator)
                AppView(simulator: simulator)
                BatteryView(simulator: simulator)
                DataView(simulator: simulator)
                LocationView(simulator: simulator)
            }.disabled(simulator.state != .booted)
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
