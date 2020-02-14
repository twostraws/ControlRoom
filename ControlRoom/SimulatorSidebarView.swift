//
//  SimulatorSidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SimulatorSidebarView: View {
    let simulator: Simulator

    private var statusImage: NSImage {
        let name: NSImage.Name
        switch simulator.state {
        case .booting: name = NSImage.statusPartiallyAvailableName
        case .shuttingDown: name = NSImage.statusPartiallyAvailableName
        case .booted: name = NSImage.statusAvailableName
        default: name = NSImage.statusNoneName
        }
        return NSImage(named: name)!
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(nsImage: statusImage)
            Image(nsImage: simulator.image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(maxWidth: 24)
            Text(simulator.name)
            Spacer()
        }
    }
}

struct SimulatorSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorSidebarView(simulator: .example)
    }
}
