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
    var body: some View {
        Text("Loading failed. This usually happens because the command /usr/bin/xcrun can't be found.")
    }
}

struct LoadingFailed_Previews: PreviewProvider {
    static var previews: some View {
        LoadingFailedView()
    }
}
