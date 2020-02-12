//
//  SidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SidebarView: View {
    var simulators: [Simulator]

    let selectedSimulator: Binding<Simulator?>

    var body: some View {
        GeometryReader { _ in
            List(selection: self.selectedSimulator) {
                ForEach(self.simulators) { simulator in
                    HStack {
                        Text(simulator.name)
                        Spacer()
                    }
                    .tag(simulator)
                }
            }
            .listStyle(SidebarListStyle())
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    @State static var selected: Simulator?

    static var previews: some View {
        SidebarView(simulators: [.example], selectedSimulator: $selected)
    }
}
