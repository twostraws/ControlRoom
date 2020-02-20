//
//  PreferencesView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: Preferences
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {

            Section(header: Text("Main Window")) {
                Toggle("Keep window on top", isOn: $preferences.wantsFloatingWindow)
                Toggle("Show Default simulator", isOn: $preferences.showDefaultSimulator)
                Toggle("Show booted devices first", isOn: $preferences.showBootedDevicesFirst)
            }

            Button("Done") {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(20)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
