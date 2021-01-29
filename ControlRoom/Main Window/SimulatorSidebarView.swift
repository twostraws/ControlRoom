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
    let canShowContextualMenu: Bool

    @State private var action: Action?
    @State private var newName: String

    init(simulator: Simulator, canShowContextualMenu: Bool) {
        self.simulator = simulator
        self.canShowContextualMenu = canShowContextualMenu
        self._newName = State(initialValue: simulator.name)
    }

    private var simulatorSummary: String {
        [simulator.name, simulator.runtime?.name]
            .compactMap { $0 }
            .joined(separator: " - ")
    }

    private var statusImage: NSImage {
        let name: NSImage.Name

        switch simulator.state {
        case .booting:
            name = NSImage.statusPartiallyAvailableName
        case .shuttingDown:
            name = NSImage.statusPartiallyAvailableName
        case .booted:
            name = NSImage.statusAvailableName
        default:
            name = NSImage.statusNoneName
        }

        return NSImage(named: name)!
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(nsImage: statusImage)
            Image(nsImage: simulator.image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(maxWidth: 24, alignment: .center)
                .padding(.top, 2)
                .shadow(color: .primary, radius: 1)
            Text(simulator.name)
            Spacer()
        }
        .contextMenu(
            ContextMenu(shouldDisplay: canShowContextualMenu) {
                Button("Rename...") { action = .rename }
                Button("Clone...") { action = .clone }
                    .disabled(simulator.state == .booted)
                Button("Delete...") { action = .delete }
            }
        )
        .sheet(item: $action) { action in
            if action == .delete {
                SimulatorActionSheet(
                    icon: simulator.image,
                    message: action.sheetTitle,
                    informativeText: action.sheetMessage,
                    confirmationTitle: action.saveActionTitle,
                    confirm: { performAction(action) }
                )
            } else {
                SimulatorActionSheet(
                    icon: simulator.image,
                    message: action.sheetTitle,
                    informativeText: action.sheetMessage,
                    confirmationTitle: action.saveActionTitle,
                    confirm: { performAction(action) },
                    canConfirm: newName.isNotEmpty,
                    content: {
                        TextField("Name", text: $newName)
                    }
                )
            }
        }
    }

    private func performAction(_ action: Action) {
        guard newName.isNotEmpty else { return }

        switch action {
        case .rename: SimCtl.rename(simulator.udid, name: newName)
        case .clone: SimCtl.clone(simulator.udid, name: newName)
        case .delete: SimCtl.delete([simulator.udid])
        }
    }
}

struct SimulatorSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorSidebarView(simulator: .example, canShowContextualMenu: true)
    }
}
