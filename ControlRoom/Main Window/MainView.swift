//
//  MainView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Hosts a LoadingView followed by the main ControlView, or a LoadingFailedView if simctl failed.
struct MainView: View {
    @ObservedObject var controller: SimulatorsController
    @EnvironmentObject var uiState: UIState

    var body: some View {
		Group {
			switch controller.loadingStatus {
			case .failed:
				LoadingFailedView(
					title: "Loading failed",
					text: "This usually happens because the command /usr/bin/xcrun can't be found."
				)
			case .invalidCommandLineTool:
				LoadingFailedView(
					title: "Loading failed. You need to use Xcode 11.4+ and install the command line tools.",
					text: "If you already have Xcode 11.4+ installed, go to Xcode's Preferences, choose the Locations tab, then make sure Xcode is selected for Command Line Tools."
				)
			case .success:
				SplitLayoutView(controller: controller)
			default:
				LoadingView()
			}
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 550, maxHeight: .infinity)
        .sheet(item: $uiState.currentSheet, content: sheetView)
        .alert(item: $uiState.currentAlert, content: alert)
    }

    private func sheetView(for sheet: UIState.Sheet) -> some View {
        Group {
			switch sheet {
			case .preferences:
				SettingsView()
			case .createSimulator:
				CreateSimulatorActionSheet(controller: controller)
			case .deepLinkEditor:
				DeepLinkEditorView()
			case .notificationEditor:
				NotificationEditorView()
			case .confirmDeleteSelected:
				SimulatorActionSheet(
					icon: controller.selectedSimulators[0].image,
					message: "Delete Simulators?",
					informativeText: "Are you sure you want to delete the selected simulators? You will not be able to undo this action.",
					confirmationTitle: "Delete",
					confirm: deleteSelectedSimulators,
					content: EmptyView.init
				)
			}
        }
    }
    /// Deletes all simulators that are currently selected.
    func deleteSelectedSimulators() {
        guard controller.selectedSimulatorIDs.isNotEmpty else { return }
        SimCtl.delete(controller.selectedSimulatorIDs)
    }

    private func alert(for alert: UIState.Alert) -> Alert {
        if alert == .confirmDeleteUnavailable {
            let confirmButton = Alert.Button.default(Text("Confirm")) {
                SimCtl.execute(.delete(.unavailable))
            }

            return Alert(title: Text("Are you sure you want to delete all unavailable simulators?"), primaryButton: confirmButton, secondaryButton: .cancel())
        } else {
            return Alert(title: Text("Unknown Alert"))
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(controller: SimulatorsController(preferences: Preferences()))
            .environmentObject(UIState.shared)
    }
}
