//
//  LoadingFailedView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Shown when loading the simulator data from simctl has failed.
struct LoadingFailedView: View {
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.headline)
                .padding(.horizontal)

            Text(text)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct LoadingFailed_Previews: PreviewProvider {
    static var previews: some View {
        LoadingFailedView(title: "Lorem ipsum", text: "Dolor sit amet")
    }
}
