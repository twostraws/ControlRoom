//
//  SettingsView.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        TabView {
            Form {
                Toggle("Keep window on top", isOn: $preferences.wantsFloatingWindow)
                Toggle("Show Default simulator", isOn: $preferences.showDefaultSimulator)
                Toggle("Show booted devices first", isOn: $preferences.showBootedDevicesFirst)
                Toggle("Show icon in menu bar", isOn: $preferences.wantsMenuBarIcon)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("Window", systemImage: "macwindow")
            }

            Form {
                HStack {
                    Text("Resend last push notification")
                    KeyboardShortcuts.Recorder(for: .resendLastPushNotification)
                }

                HStack {
                    Text("Restart last selected app")
                    KeyboardShortcuts.Recorder(for: .restartLastSelectedApp)
                }

                HStack {
                    Text("Reopen last URL")
                    KeyboardShortcuts.Recorder(for: .reopenLastURL)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }

            Form {
                TextField(
                    "Path to Terminal",
                    text: $preferences.terminalAppPath
                )
                .textFieldStyle(.roundedBorder)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("Locations", systemImage: "externaldrive")
            }
            .onChange(of: preferences.wantsMenuBarIcon) { newValue in
                #warning("FIXME: Commented out")
    //            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
    //
    //            if newValue {
    //                appDelegate.addMenuBarItem()
    //            } else {
    //                appDelegate.removeMenuBarItem()
    //            }
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Preferences())
    }
}
