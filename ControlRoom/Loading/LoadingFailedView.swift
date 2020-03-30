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

    let errorMessage: String

    var body: some View {
        Text(errorMessage)
    }
}

struct LoadingFailed_Previews: PreviewProvider {
    static var previews: some View {
        LoadingFailedView(errorMessage: "Lorem ipsum")
    }
}
