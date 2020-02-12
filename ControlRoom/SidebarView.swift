//
//  SidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var controller: SimulatorsController

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                List(selection: self.$controller.selectedSimulator) {
                    ForEach(self.controller.simulators) { simulator in
                        Text(simulator.name)
                            .tag(simulator)
                    }
                }
                .listStyle(SidebarListStyle())

                Divider()

                FilterField("Filter", text: self.$controller.filterText)
                    .padding(2)
            }
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    @State static var selected: Simulator?

    static var previews: some View {
        SidebarView(controller: SimulatorsController())
    }
}
