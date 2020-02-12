//
//  SplitLayoutView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SplitLayoutView: View {
    
    var simulators: [Simulator]
    @State var selected: Simulator?
    
    var body: some View {
        HSplitView {
            SidebarView(simulators: simulators, selectedSimulator: $selected)
                .frame(minWidth: 200)
            
            // use a GeometryReader here to take up as much space as possible
            // otherwise the view would collapse down to (potentially)
            // the size of the Text
            GeometryReader { _ in
                if self.selected == nil {
                    Text("Select a simulator from the list")
                } else {
                    ControlView(simulator: self.selected!)
                        .padding()
                }
            }
        }
    }
}

struct SplitLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        SplitLayoutView(simulators: [.example], selected: nil)
    }
}
