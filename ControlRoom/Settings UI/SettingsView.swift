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
                Picker("Screenshot Format:", selection: $captureSettings.imageFormat) {
                    ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                        Text(type.rawValue.uppercased()).tag(type)
                    }
                }

                Picker("Video Format:", selection: $captureSettings.videoFormat) {
                    ForEach(SimCtl.IO.VideoFormat.all, id: \.self) { item in
                        if item == .divider {
                            Divider()
                        } else {
                            Text(item.name).tag(item)
                        }
                    }
                }

                Picker("Display:", selection: $captureSettings.display) {
                    ForEach(SimCtl.IO.Display.allCases, id: \.self) { display in
                        Text(display.rawValue.capitalized).tag(display)
                    }
                }

                Picker("Mask:", selection: $captureSettings.mask) {
                    ForEach(SimCtl.IO.Mask.allCases, id: \.self) { mask in
                        Text(mask.rawValue.capitalized).tag(mask)
                    }
                }
                .disabled(renderChrome)

                Toggle(isOn: $renderChrome.onChange(updateChromeSettings)) {
                    VStack(alignment: .leading) {
                        Text("Add device chrome to screenshots")
                        Text("This is an experimental feature and may not function properly yet.")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Screenshots", systemImage: "camera.on.rectangle")
            }

            VStack {
                Toggle("Uppercase Hex Strings", isOn: $uppercaseHex)
                    .padding(.bottom)

                Text("Set the maximum number of decimal places to use when generating code for picked simulator colors. The default is 2.")
                Stepper("Decimal Places: \(colorPickerAccuracy)", value: $colorPickerAccuracy, in: 0...5)
                    .pickerStyle(.segmented)
            }
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
