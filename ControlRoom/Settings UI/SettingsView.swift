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

    /// The user's settings for capturing
    @AppStorage("captureSettings") var captureSettings = CaptureSettings(imageFormat: .png, videoFormat: .h264, display: .internal, mask: .ignored)

    /// Whether the user wants us to render device bezels around their screenshots.
    /// Note: this requires a mask of alpha, so we enforce that when true.
    @AppStorage("renderChrome") var renderChrome = false

    /// How many decimal places to use for rounding picked colors.
    @AppStorage("CRColorPickerAccuracy") var colorPickerAccuracy = 2

    /// Whether hex strings should be printed in uppercase or not.
    @AppStorage("CRColorPickerUppercaseHex") var uppercaseHex = true

    var body: some View {
        TabView {
            TogglesFormView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Window", systemImage: "macwindow")
                }

            NotificationsFormView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            makePickersForm()
                .padding()
                .tabItem {
                    Label("Screenshots", systemImage: "camera.on.rectangle")
                }

            makeColorPicker()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem {
                    Label("Colors", systemImage: "paintpalette")
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
        }
        .frame(minWidth: 550)
    }

    func updateChromeSettings() {
        if renderChrome {
            captureSettings.mask = .alpha
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Preferences())
    }
}
