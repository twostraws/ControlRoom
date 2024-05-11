//
//  TogglesFormView.swift
//  ControlRoom
//
//  Created by Elliot Knight on 11/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI

struct TogglesFormView: View {
    @EnvironmentObject private var preferences: Preferences
    var body: some View {
        Form {
            Toggle("Keep window on top", isOn: $preferences.wantsFloatingWindow)
            Toggle("Show Default simulator", isOn: $preferences.showDefaultSimulator)
            Toggle("Show booted devices first", isOn: $preferences.showBootedDevicesFirst)
            Toggle("Show icon in menu bar", isOn: $preferences.wantsMenuBarIcon)
        }
    }
}

#Preview {
    TogglesFormView()
        .environmentObject(Preferences())
}
