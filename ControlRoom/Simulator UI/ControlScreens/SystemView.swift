//
//  SystemView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import CoreLocation
import SwiftUI

/// Controls system-wide settings such as time and appearance.
struct SystemView: View {
    @EnvironmentObject var preferences: Preferences
    let simulator: Simulator

    /// The current time to show in the device.
    @State private var time = Date()

    /// The system-wide appearance; "Light" or "Dark".
    @State private var appearance: SimCtl.UI.Appearance = .light

    /// The currently active language identifier
    @State private var language: String = NSLocale.current.languageCode ?? ""

    /// The currently active locale identifier
    @State private var locale: String = NSLocale.current.identifier

    private let languages: [String] = {
        NSLocale.isoLanguageCodes
            .filter { NSLocale.current.localizedString(forLanguageCode: $0) != nil }
            .sorted { lhs, rhs in
                let lhsString = NSLocale.current.localizedString(forLanguageCode: lhs) ?? ""
                let rhsString = NSLocale.current.localizedString(forLanguageCode: rhs) ?? ""
                return lhsString.lowercased() < rhsString.lowercased()
            }
    }()

    var body: some View {
        Form {
            Group {
                HStack {
                    DatePicker("Time:", selection: $time)
                    Button("Set", action: setTime)
                    Button("Set to 9:41", action: setAppleTime)
                }

                FormSpacer()
            }

            Group {
                Picker("Appearance:", selection: $appearance.onChange(updateAppearance)) {
                    ForEach(SimCtl.UI.Appearance.allCases, id: \.self) {
                        Text($0.displayName)
                    }
                }

                FormSpacer()
            }

            Group {
                Picker("Language:", selection: $language) {
                    ForEach(languages, id: \.self) {
                        Text(NSLocale.current.localizedString(forLanguageCode: $0) ?? "")
                    }
                }

                Picker("Locale:", selection: $locale) {
                    ForEach(locales(for: language), id: \.self) {
                        Text(NSLocale.current.localizedString(forIdentifier: $0) ?? "")
                    }
                }
                HStack {
                    Button("Set Language/Locale", action: updateLanguage)
                    Text("(Requires Reboot)").font(.system(size: 11)).foregroundColor(.secondary)
                }

                FormSpacer()
            }

            Group {
                Section {
                    Button("Trigger iCloud Sync", action: triggerSync)
                }

                FormSpacer()
            }

            Group {
                Section(header: Text("Copy Pasteboard")) {
                    HStack {
                        Button("Simulator → Mac", action: copyPasteboardToMac)
                        Button("Mac → Simulator", action: copyPasteboardToSim)
                    }
                }

                FormSpacer()
            }

            Group {
                Section(header: Text("Open URL")) {
                    HStack {
                        TextField("URL / deep link to open", text: $preferences.lastOpenURL)
                        Button("Open URL", action: openURL)
                    }
                }

            }

            Spacer()

            HStack {
                Spacer()
                Button("Reset Keychain", action: resetKeychain)
                Button("Erase Content and Settings", action: eraseDevice)
            }
        }
        .tabItem {
            Text("System")
        }
        .padding()
    }

    /// Changes the system clock to a new value.
    func setTime() {
        SimCtl.overrideStatusBarTime(simulator.udid, time: time)
    }

    func setAppleTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 41
        components.second = 0

        let appleTime = calendar.date(from: components) ?? Date()
        SimCtl.overrideStatusBarTime(simulator.udid, time: appleTime)

        time = appleTime
    }

    /// Moves between light and dark mode.
    func updateAppearance() {
        SimCtl.setAppearance(simulator.udid, appearance: appearance)
    }

    func updateLanguage() {
        let plistPath = simulator.dataPath + "/Library/Preferences/.GlobalPreferences.plist"
        _ = Process.execute("/usr/bin/xcrun", arguments: ["plutil", "-replace", "AppleLanguages", "-json", "[\"\(language)\" ]", plistPath])
        _ = Process.execute("/usr/bin/xcrun", arguments: ["plutil", "-replace", "AppleLocale", "-string", locale, plistPath])
        SimCtl.reboot(simulator.id)
    }

    /// Starts an immediate iCloud sync.
    func triggerSync() {
        SimCtl.triggeriCloudSync(simulator.udid)
    }

    /// Copies the simulator's pasteboard to the Mac.
    func copyPasteboardToMac() {
        SimCtl.copyPasteboardToMac(simulator.udid)
    }

    /// Copies the Mac's pasteboard to the simulator.
    func copyPasteboardToSim() {
        SimCtl.copyPasteboardToSimulator(simulator.udid)
    }

    /// Opens a URL in the appropriate device app.
    func openURL() {
        SimCtl.openURL(simulator.udid, URL: preferences.lastOpenURL)
    }

    /// Erases the current device.
    func eraseDevice() {
        SimCtl.erase(simulator.udid)
    }

    /// Resets the keychain on the current device
    func resetKeychain() {
        SimCtl.execute(.keychain(deviceId: simulator.udid, action: .reset))
    }

    private func locales(for language: String) -> [String] {
        NSLocale.availableLocaleIdentifiers
            .filter { $0.hasPrefix(language) }
            .sorted { (lhs, rhs) -> Bool in
                let lhsString = NSLocale.current.localizedString(forIdentifier: lhs) ?? ""
                let rhsString = NSLocale.current.localizedString(forIdentifier: rhs) ?? ""
                return lhsString.lowercased() < rhsString.lowercased()
            }
    }
}

struct SystemView_Previews: PreviewProvider {
    static var previews: some View {
        SystemView(simulator: .example)
    }
}

extension SimCtl.UI.Appearance {
    var displayName: String {
        rawValue.capitalized
    }
}
