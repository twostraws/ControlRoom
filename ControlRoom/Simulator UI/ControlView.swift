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
                AppView(simulator: simulator, applications: applications)
                BatteryView(simulator: simulator)
                LocationView(controller: controller, simulator: simulator)
                NetworkView(simulator: simulator)
                ScreenView(simulator: simulator)
            }
            .disabled(simulator.state != .booted)
        }
        .padding()
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
    }
}
