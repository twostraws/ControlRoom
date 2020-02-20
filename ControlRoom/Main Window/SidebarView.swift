//
//  SidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Shows the list of available simulators.
struct SidebarView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject var controller: SimulatorsController

    @State private var shouldShowDeleteAlert = false

    private var selectedSimulatorsSummary: String {
        guard
            controller.selectedSimulators.count > 0
            else {
                return ""
            }
        switch controller.selectedSimulators.count {
        case 1:
            return controller.selectedSimulators[0].summary
        default:
            let simulatorsSummaries = controller.selectedSimulators.map { "• \($0.summary)" }.joined(separator: "\n")
            return "the following simulators? \n\n\(simulatorsSummaries)"
        }

    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                List(selection: self.$controller.selectedSimulatorIDs) {
                    if self.controller.simulators.isEmpty {
                        Text("No simulators")
                    } else {
                        ForEach(Simulator.Platform.allCases, id: \.self) { platform in
                            self.section(for: platform)
                        }
                    }
                }
                .contextMenu {
                    if self.controller.selectedSimulatorIDs.count > 0 {
                        Button("Delete...") {
                            self.shouldShowDeleteAlert = true
                        }
                    }
                }
                .listStyle(SidebarListStyle())

                Divider()

                HStack(spacing: 4) {
                    Button(action: { self.preferences.shouldShowOnlyActiveDevices.toggle() }, label: {
                        Image("power")
                        .resizable()
                        .foregroundColor(self.preferences.shouldShowOnlyActiveDevices ? .accentColor : .secondary)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16)
                        .padding(.horizontal, 2)
                    })
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.leading, 3)
                    FilterField("Filter", text: self.$preferences.filterText)
                }
                .padding(2)
                .sheet(isPresented: self.$shouldShowDeleteAlert) {
                    SimulatorActionSheet(icon: self.controller.selectedSimulators[0].image,
                                         message: "Delete Simulators?",
                                         informativeText: "Are you sure you want to delete the selected simulators? You will not be able to undo this action.",
                                         confirmationTitle: "Delete",
                                         confirm: self.deleteSelectedSimulators,
                                         content: { EmptyView() })
                }
            }
        }
    }

    private func section(for platform: Simulator.Platform) -> some View {
        let simulators = controller.simulators.filter({ $0.platform == platform })
        let canShowContext = controller.selectedSimulatorIDs.count < 2

        return Group {
            if simulators.isEmpty {
                EmptyView()
            } else {
                Section(header: Text(platform.displayName.uppercased())) {
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
        guard controller.selectedSimulatorIDs.count > 0 else { return }
        SimCtl.delete(controller.selectedSimulatorIDs)
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
