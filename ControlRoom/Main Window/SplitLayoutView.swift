//
//  SplitLayoutView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A horizontal split view that shows a left-hand sidebar of simulators and right-hand details.
struct SplitLayoutView: View {
    @ObservedObject var controller: SimulatorsController

    var body: some View {
        NavigationView {
            SidebarView(controller: controller)
                .frame(minWidth: 220)
                .layoutPriority(1)

            // Use a GeometryReader here to take up as much space as possible
            // otherwise the view would collapse down to (potentially)
            // the size of the Text.
            GeometryReader { _ in
                if controller.selectedSimulatorIDs.count == 1 {
                    ControlView(controller: controller,
                                simulator: controller.selectedSimulators[0],
                                applications: controller.applications)
                        .padding()
                } else {
                    Text("Select a simulator from the list.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .layoutPriority(2)
        }
    }
}

struct SplitLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        SplitLayoutView(controller: SimulatorsController(preferences: Preferences()))
    }
}
