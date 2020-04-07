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
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var uiState: UIState

    var body: some View {
        Group {
            if controller.loadingStatus == .failed {
                LoadingFailedView(title: "Loading failed", text: "This usually happens because the command /usr/bin/xcrun can't be found.")
            } else if controller.loadingStatus == .invalidCommandLineTool {
                LoadingFailedView(title: "Loading failed. You need to use Xcode 11.4+ and install the command line tools.",
                                  text: "If you already have Xcode 11.4+ installed, go to Xcode's Preferences, choose the Locations tab, then make sure Xcode is selected for Command Line Tools.")
            } else if controller.loadingStatus == .success {
                SplitLayoutView(controller: self.controller)
            } else {
                LoadingView()
            }
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        .sheet(item: $uiState.currentSheet, content: sheetView)
    }

    private func sheetView(for sheet: UIState.Sheet) -> some View {
        Group {
            if sheet == .preferences {
                PreferencesView()
                    .environmentObject(preferences)
            } else if sheet == .createSimulator {
                CreateSimulatorActionSheet(controller: controller)
            } else if sheet == .notificationEditor {
                NotificationEditorView()
                    .environmentObject(preferences)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let prefs = Preferences()
        return MainView(controller: SimulatorsController(preferences: prefs))
    }
}
