//
//  SnapshotsView.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 14/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SnapshotsView: View {
	let simulator: Simulator
	@ObservedObject var controller: SimulatorsController

    @State private var snapshotAction: SnapshotAction?
    @State private var newName: String
    @State private var selectedSnapshotName: String

    init(simulator: Simulator, controller: SimulatorsController) {
        self.simulator = simulator
        self.controller = controller
        self._newName = State(initialValue: simulator.name)
        self._selectedSnapshotName = State(initialValue: simulator.name)
    }

    private let formatter = MeasurementFormatter()

	var body: some View {
		ScrollView {
            if controller.snapshots.count > 0 {
                Form {
					Section {
						LabeledContent("Snapshots:") {
							VStack(alignment: .leading, spacing: 5) {
                                ForEach(controller.snapshots.sorted(by: { $0.creationDate > $1.creationDate }), id: \.id) { snapshot in

                                    let folderSize = Measurement(value: Double(snapshot.size), unit: UnitInformationStorage.bytes)

									HStack {
                                        Button {
                                            restore(snapshot: snapshot.id)
                                        } label: {
                                            Label("Restore", systemImage: "arrow.counterclockwise")
                                        }

                                        Button {
                                            rename(snapshot: snapshot.id)
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }

                                        Text(snapshot.id)
                                            .fontWeight(.semibold)

                                        Group {
                                            Text(snapshot.creationDate.formatted(date: .numeric, time: .standard))
                                            Text(formatter.string(from: folderSize.converted(to: .gigabytes)))
                                        }
                                        .font(.callout)
                                        .fontWeight(.thin)

                                        Button {
                                            delete(snapshot: snapshot.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Spacer()
									}
								}
							}
						}
					}
                }
                .padding()
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: simulator.deviceFamily.snapshotUnavailableIcon)
                    Text("No snapshots yet")
                }
                .font(.title)
			}
		}
        .tabItem {
            Text("Snapshots")
        }
        .sheet(item: $snapshotAction) { action in
            switch action {
            case .rename:
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
            case .delete, .restore:
                SimulatorActionSheet(
                    icon: simulator.image,
                    message: action.sheetTitle,
                    informativeText: action.sheetMessage,
                    confirmationTitle: action.saveActionTitle,
                    confirm: { performAction(action) })
            }
        }

	}

    private func rename(snapshot: String) {
        selectedSnapshotName = snapshot
        newName = snapshot
        snapshotAction = .rename
    }

    private func delete(snapshot: String) {
        selectedSnapshotName = snapshot
        snapshotAction = .delete
    }

    private func restore(snapshot: String) {
        selectedSnapshotName = snapshot
        snapshotAction = .restore
    }

    private func performAction(_ action: SnapshotAction) {
        switch action {
        case .delete: SnapshotCtl.deleteSnapshot(deviceId: simulator.udid, snapshotName: selectedSnapshotName)
        case .rename: SnapshotCtl.renameSnapshot(deviceId: simulator.udid, snapshotName: selectedSnapshotName, newSnapshotName: newName)
        case .restore: SnapshotCtl.restoreSnapshot(deviceId: simulator.udid, snapshotName: selectedSnapshotName)
        }
    }

	func placeholder() {}

}
