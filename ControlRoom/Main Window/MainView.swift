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
    @EnvironmentObject var controller: SimulatorsController

    var body: some View {
        Group {
            if controller.loadingStatus == .loading {
                LoadingView()
            } else if controller.loadingStatus == .success {
                SplitLayoutView()
            } else {
                LoadingFailedView()
            }
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let prefs = Preferences()
        return MainView().environmentObject(SimulatorsController(preferences: prefs))
    }
}
