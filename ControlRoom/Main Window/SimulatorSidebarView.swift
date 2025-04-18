//
//  SimulatorSidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI
import KeyboardShortcuts

/// Shows one simulator in the sidebar.
struct SimulatorSidebarView: View {
    var simulator: Simulator
    let canShowContextualMenu: Bool

    @State private var action: Action?
    @State private var newName: String

    init(simulator: Simulator, canShowContextualMenu: Bool) {
        self.simulator = simulator
        self.canShowContextualMenu = canShowContextualMenu
        self._newName = State(initialValue: simulator.name)
    }

    private var simulatorSummary: String {
        [simulator.name, (simulator.runtime?.version).map { "(\($0))" }]
            .compactMap { $0 }
            .joined(separator: " ")
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
            Text(simulatorSummary)
        }
        .frame(alignment: .leading)
        .contextMenu(
            ContextMenu(shouldDisplay: canShowContextualMenu) {
                Button("\(simulator.state.menuActionName)") { performAction(.power) }
                    .disabled(!simulator.state.isActionAllowed)
                Divider()
                Button("Rename...") { action = .rename }
                Button("Clone...") { action = .clone }
                    .disabled(simulator.state == .booted)
                Button("Create snapshot...") { performAction(.createSnapshot) }
                Button("Delete...") { action = .delete }
                Divider()
                Button("Open in Finder") { performAction(.openRoot) }
            }
        )
        .sheet(item: $action) { action in
            switch action {
            case .power, .openRoot, .createSnapshot:
                EmptyView()
            case .rename, .clone:
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
            case .delete:
                SimulatorActionSheet(
                    icon: simulator.image,
                    message: action.sheetTitle,
                    informativeText: action.sheetMessage,
                    confirmationTitle: action.saveActionTitle,
                    confirm: { performAction(action) })
            }
        }
    }

    private func performAction(_ action: Action) {
        guard newName.isNotEmpty else { return }

        switch action {
        case .rename: SimCtl.rename(simulator.udid, name: newName)
        case .clone: SimCtl.clone(simulator.udid, name: newName)
        case .createSnapshot: SnapshotCtl.createSnapshot(deviceId: simulator.udid, snapshotName: UUID().uuidString)
        case .delete: SimCtl.delete([simulator.udid])
        case .power:
            if simulator.state == .booted {
                SimCtl.shutdown(simulator.udid)
            } else if simulator.state == .shutdown {
                SimCtl.boot(simulator)
            }
        case .openRoot:
            simulator.open(.root)
        }
    }
}

struct SimulatorSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorSidebarView(simulator: .example, canShowContextualMenu: true)
    }
}
