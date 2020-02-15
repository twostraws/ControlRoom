//
//  SimulatorSidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Shows one simulator in the sidebar.
struct SimulatorSidebarView: View {
    let simulator: Simulator

    @State private var shouldShowDeleteAlert = false

    private var simulatorSummary: String {
        [simulator.name, simulator.runtime?.name]
            .compactMap { $0 }
            .joined(separator: " - ")
    }

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
        .contextMenu {
            Button("Delete") {
                self.shouldShowDeleteAlert = true
            }
        }
        .alert(isPresented: $shouldShowDeleteAlert) {
            Alert(title: Text("Are you sure you want to permanently delete \(simulatorSummary)?"),
                  message: Text("You can’t undo this action."),
                  primaryButton: .destructive(Text("Delete the simulator"), action: deleteSelectedSimulator),
                  secondaryButton: .default(Text("Cancel")))
        }
    }

    /// Deletes all simulators that are currently selected.
    private func deleteSelectedSimulator() {
        SimCtl.delete([simulator.udid])
    }
}

struct SimulatorSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorSidebarView(simulator: .example)
    }
}
