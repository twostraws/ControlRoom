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

    enum Action: Int, Identifiable {
        case rename
        case clone
        case delete

        var id: Int { rawValue }

        var sheetTitle: String {
            switch self {
            case .rename: return "Rename Simulator"
            case .clone: return "Clone Simulator"
            case .delete: return "Delete Simulator"
            }
        }

        var sheetMessage: String {
            switch self {
            case .rename: return "Enter a new name for this simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
            case .clone: return "Enter a name for the new simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
            case .delete: return "Are you sure you want to delete this simulator? You will not be able to undo this action."
            }
        }

        var saveActionTitle: String {
            switch self {
            case .rename: return "Rename"
            case .clone: return "Clone"
            case .delete: return "Delete"
            }
        }
    }

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
        .contextMenu(ContextMenu(shouldDisplay: canShowContextualMenu) {
            Button("Rename...") { self.action = .rename }
            Button("Clone...") { self.action = .clone }
                .disabled(simulator.state == .booted)
            Button("Delete...") { self.action = .delete }
        })
        .sheet(item: self.$action) { action in
            if action == .delete {
                SimulatorActionSheet(icon: self.simulator.image,
                                     message: action.sheetTitle,
                                     informativeText: action.sheetMessage,
                                     confirmationTitle: action.saveActionTitle,
                                     confirm: { self.performAction(action) })
            } else {
                SimulatorActionSheet(icon: self.simulator.image,
                                     message: action.sheetTitle,
                                     informativeText: action.sheetMessage,
                                     confirmationTitle: action.saveActionTitle,
                                     confirm: { self.performAction(action) },
                                     canConfirm: self.newName.isNotEmpty,
                                     content: {
                                        TextField("Name", text: self.$newName)
                })
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
