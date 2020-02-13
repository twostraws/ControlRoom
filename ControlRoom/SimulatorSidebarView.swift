//
//  SimulatorSidebarView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct SimulatorSidebarView: View {
    let simulator: Simulator

    var body: some View {
        HStack {
            Image(nsImage: simulator.image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(maxWidth: 24)
            Text(simulator.name)
            Spacer()
        }
    }
}

struct SimulatorSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorSidebarView(simulator: .example)
    }
}
