//
//  SidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Shows the list of available simulators, allowing selection, filtering, and deletion.
struct SidebarView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject var controller: SimulatorsController

    @State private var shouldShowDeleteAlert = false

    private var selectedSimulatorsSummary: String {
        guard controller.selectedSimulators.count > 0 else { return "" }

        switch controller.selectedSimulators.count {
        case 1:
            return controller.selectedSimulators[0].summary
        default:
            let simulatorsSummaries = controller.selectedSimulators.map { "• \($0.summary)" }.joined(separator: "\n")
            return "the following simulators? \n\n\(simulatorsSummaries)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $controller.selectedSimulatorIDs.onChange(updateSelectedSimulators)) {
                if controller.simulators.isEmpty {
                    Text("No simulators")
                } else {
                    ForEach(SimCtl.DeviceFamily.allCases, id: \.self, content: section)
                }
            }
            .contextMenu {
                if controller.selectedSimulatorIDs.isNotEmpty {
                    Button("Delete...") {
                        shouldShowDeleteAlert = true
                    }
                }
            }
            .listStyle(SidebarListStyle())

            Divider()

            HStack(spacing: 4) {
                Button {
                    preferences.shouldShowOnlyActiveDevices.toggle()
                } label: {
                    Image("power")
                        .resizable()
                        .foregroundColor(preferences.shouldShowOnlyActiveDevices ? .accentColor : .secondary)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.leading, 3)

                FilterField("Filter", text: $preferences.filterText)
            }
            .padding(2)
            .sheet(isPresented: $shouldShowDeleteAlert) {
                SimulatorActionSheet(
                    icon: controller.selectedSimulators[0].image,
                    message: "Delete Simulators?",
                    informativeText: "Are you sure you want to delete the selected simulators? You will not be able to undo this action.",
                    confirmationTitle: "Delete",
                    confirm: deleteSelectedSimulators,
                    content: { EmptyView() }
                )
            }
        }
    }

    private func section(for family: SimCtl.DeviceFamily) -> some View {
        let simulators = controller.simulators.filter { $0.deviceFamily == family }
        let canShowContext = controller.selectedSimulatorIDs.count < 2

        return Group {
            if simulators.isEmpty {
                EmptyView()
            } else {
                Section(header: Text(family.displayName)) {
                    ForEach(simulators) { simulator in
                        SimulatorSidebarView(simulator: simulator, canShowContextualMenu: canShowContext)
                            .tag(simulator.udid)
                    }
                }
            }
        }
    }

    /// Deletes all simulators that are currently selected.
    func deleteSelectedSimulators() {
        guard controller.selectedSimulatorIDs.isNotEmpty else { return }
        SimCtl.delete(controller.selectedSimulatorIDs)
    }

    /// Called whenever the user adjusts their selection of simulator.
    func updateSelectedSimulators() {
        // If we selected exactly one simulator, stash its UDID away so we can
        // quickly use it elsewhere in the app, e.g. in the menu bar icon.
        if controller.selectedSimulatorIDs.count == 1 {
            preferences.lastSimulatorUDID = controller.selectedSimulators.first!.udid
        }
    }
}

private extension Simulator {
    var summary: String {
        [name, runtime?.name].compactMap { $0 }.joined(separator: " - ")
    }
}

struct SidebarView_Previews: PreviewProvider {
    @State static var selected: Simulator?

    static var previews: some View {
        SidebarView(controller: SimulatorsController(preferences: Preferences()))
    }
}
