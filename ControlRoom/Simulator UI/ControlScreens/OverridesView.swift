//
//  OverridesView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 07/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

struct OverridesView: View {
    let simulator: Simulator

    /// The current time to show in the device.
    @State private var time = Date.now

    /// The system-wide appearance; "Light" or "Dark".
    @State private var appearance: SimCtl.UI.Appearance = .light

    /// The currently active language identifier
    @State private var language: String = NSLocale.current.language.languageCode?.identifier ?? ""

    /// The currently active locale identifier
    @State private var locale: String = NSLocale.current.identifier

    // The current Dynamic Type sizes
    @State private var contentSize: SimCtl.UI.ContentSizes = .medium

    @State private var enhanceTextLegibility = false
    @State private var showButtonShapes = false
    @State private var showOnOffLabels = false
    @State private var reduceTransparency = false
    @State private var increaseContrast = false
    @State private var differentiateWithoutColor = false
    @State private var smartInvert = false

    @State private var reduceMotion = false
    @State private var preferCrossFadeTransitions = false

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
        ScrollView {
            Form {
                Group {
                    HStack {
                        DatePicker("Time:", selection: $time)
                        Button("Set", action: setTime)
                        Button("Set to 9:41", action: setAppleTime)
                    }
                    Divider()
                }
                Group {
                    Picker("Appearance:", selection: $appearance.onChange(updateAppearance)) {
                        ForEach(SimCtl.UI.Appearance.allCases, id: \.self) {
                            Text($0.displayName)
                        }
                    }
                    Divider()
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

                    Divider()
                }
                
                Section(header:
                    Text("Accessibility overrides")
                        .font(.headline)
                ) {
                    Picker("Content Size:", selection: $contentSize) {
                        ForEach(SimCtl.UI.ContentSizes.allCases, id: \.self) { size in
                            HStack {
                                Text(size.rawValue)
                            }
                        }
                    }
                    .onChange(of: contentSize) { _ in
                        updateContentSize()
                    }

                    Toggle("Bold Text", isOn: $enhanceTextLegibility.onChange(setEnhanceTextLegibility))
                    Toggle("Button Shapes", isOn: $showButtonShapes.onChange(setShowButtonShapes))
                    Toggle("On/Off Labels", isOn: $showOnOffLabels.onChange(setShowOnOffLabels))
                    Toggle("Reduce Transparency", isOn: $reduceTransparency.onChange(setReduceTransparency))
                    Toggle("Increase Contrast", isOn: $increaseContrast.onChange(setIncreaseContrast))
                    Toggle("Differentiate Without Color", isOn: $differentiateWithoutColor.onChange(setDifferentiateWithoutColor))
                    Toggle("Smart Invert", isOn: $smartInvert.onChange(setSmartInvert))
                }
                
                Toggle("Reduce Motion", isOn: $reduceMotion.onChange(setReduceMotion))
                
                Toggle("Prefer Cross-Fade Transitions", isOn: $preferCrossFadeTransitions.onChange(setPreferCrossFadeTransitions))
                    .disabled(reduceMotion == false)
            }
            .padding()
        }
        .tabItem {
            Text("Overrides")
        }
    }

    /// Changes the system clock to a new value.
    func setTime() {
        SimCtl.overrideStatusBarTime(simulator.udid, time: time)
    }

    func setAppleTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = 9
        components.minute = 41
        components.second = 0

        let appleTime = calendar.date(from: components) ?? Date.now
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

    private func locales(for language: String) -> [String] {
        NSLocale.availableLocaleIdentifiers
            .filter { $0.hasPrefix(language) }
            .sorted { (lhs, rhs) -> Bool in
                let lhsString = NSLocale.current.localizedString(forIdentifier: lhs) ?? ""
                let rhsString = NSLocale.current.localizedString(forIdentifier: rhs) ?? ""
                return lhsString.lowercased() < rhsString.lowercased()
            }
    }

    /// Update Content Size.
    func updateContentSize() {
        SimCtl.setContentSize(simulator.udid, contentSize: contentSize)
    }

    // Updates the simulator's accessibility setting for a particular key.
    // Example call: xcrun simctl spawn booted defaults write com.apple.Accessibility EnhancedTextLegibilityEnabled -bool FALSE
    func updateAccessibility(key: String, value: Bool) {
        _ = Process.execute("/usr/bin/xcrun", arguments: ["simctl", "spawn", simulator.id, "defaults", "write", "com.apple.Accessibility", key, "-bool", String(value)])
    }

    func setEnhanceTextLegibility() {
        updateAccessibility(key: "EnhancedTextLegibilityEnabled", value: enhanceTextLegibility)
    }

    func setShowButtonShapes() {
        updateAccessibility(key: "ButtonShapesEnabled", value: showButtonShapes)
    }

    func setShowOnOffLabels() {
        updateAccessibility(key: "IncreaseButtonLegibilityEnabled", value: showOnOffLabels)
    }

    func setReduceTransparency() {
        updateAccessibility(key: "EnhancedBackgroundContrastEnabled", value: reduceTransparency)
    }

    func setIncreaseContrast() {
        updateAccessibility(key: "DarkenSystemColors", value: increaseContrast)
    }

    func setDifferentiateWithoutColor() {
        updateAccessibility(key: "DifferentiateWithoutColor", value: differentiateWithoutColor)
    }

    func setSmartInvert() {
        updateAccessibility(key: "InvertColorsEnabled", value: smartInvert)
    }

    func setReduceMotion() {
        updateAccessibility(key: "ReduceMotionEnabled", value: reduceMotion)

        // Automatically disable the cross-fade animation if reduce motion is being
        // disabled. This matches what Settings does.
        if reduceMotion == false {
            updateAccessibility(key: "ReduceMotionReduceSlideTransitionsPreference", value: false)
        }
    }

    func setPreferCrossFadeTransitions() {
        updateAccessibility(key: "ReduceMotionReduceSlideTransitionsPreference", value: preferCrossFadeTransitions)
    }
}

struct OverridesView_Previews: PreviewProvider {
    static var previews: some View {
        OverridesView(simulator: .example)
            .environmentObject(Preferences())
    }
}
