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
    let simulator: Simulator

    @EnvironmentObject var preferences: Preferences

    @AppStorage("CRApps_LastOpenURL") private var lastOpenURL = ""

    @AppStorage("CRApps_LastCertificateFilePath") private var lastCertificateFilePath = ""

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

	@State var dropHovering: Bool = false

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
                        TextField("URL / deep link to open", text: $lastOpenURL)
                        Button("Open URL", action: openURL)
                    }
                }
				        FormSpacer()
                Section(header: Text("Add Root Certificate")) {
                    HStack {
                        TextField("Trusted root certificate file location", text: $lastCertificateFilePath)
                        Button("Add Root Certificate", action: addRootCertificate)
                    }
                }
          }

          Spacer()
          Group {
          Section(header: Text("Location on Disk")) {
            HStack {
              Text("Device ID")
              Spacer()
              Text(simulator.udid)
              Button("Copy", action: copyDeviceID)
            }
            HStack(alignment: .top) {
              Text("Root Path:")
              Spacer()
              Text(simulator.urlForFilePath(.root).relativePath)
            }
            HStack {
              Spacer()
              Button("Copy", action: { copyPath(.root) })
              Button("Open in Finder", action: { openInFinder(.root) })
              Button("Open in Terminal", action: { openInTerminal(.root) })
            }
            VStack {
              HStack(alignment: .top) {
                Text("Files Path:")
                Spacer()
                Text(simulator.urlForFilePath(.files).relativePath)
              }
              HStack(alignment: .bottom) {
                Text("drag file(s) here to copy").font(.caption)
                Spacer()
                Button("Copy", action: { copyPath(.files) })
                Button("Open in Finder", action: { openInFinder(.files) })
                Button("Open in Terminal", action: { openInTerminal(.files) })
              }
            }
            .padding(5)
            .overlay(
              RoundedRectangle(cornerRadius: 5)
                .stroke(dropHovering ? Color.white : Color.gray, lineWidth: 1)
            )
            .onDrop(of: [.fileURL], isTargeted: $dropHovering) { providers in
              return simulator.copyFilesFromProviders(providers, toFilePath: .files)
            }
          }
          FormSpacer()
        }

        Spacer()

            HStack {
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
        SimCtl.openURL(simulator.udid, URL: lastOpenURL)
    }

    func addRootCertificate() {
        SimCtl.addRootCertificate(simulator.udid, filePath: lastCertificateFilePath)
    }

    /// Erases the current device.
    func eraseDevice() {
        SimCtl.erase(simulator.udid)
    }

    /// Resets the keychain on the current device
    func resetKeychain() {
        SimCtl.execute(.keychain(deviceId: simulator.udid, action: .reset))
    }

	func copyDeviceID() {
		NSPasteboard.general.declareTypes([.string], owner: nil)
		NSPasteboard.general.setString(simulator.udid, forType: .string)
	}

	func copyPath(_ filePath: Simulator.FilePathKind) {
		NSPasteboard.general.declareTypes([.string], owner: nil)
		NSPasteboard.general.setString(simulator.urlForFilePath(filePath).relativePath, forType: .string)
	}

	func openInFinder(_ filePath: Simulator.FilePathKind) {
		NSWorkspace.shared.activateFileViewerSelecting([simulator.urlForFilePath(filePath)])
	}

	func openInTerminal(_ filePath: Simulator.FilePathKind) {
        guard preferences.terminalAppPath.isNotEmpty else { return }

        let terminalUrl = URL(fileURLWithPath: preferences.terminalAppPath) as CFURL
		let unmanagedTerminalUrl = Unmanaged<CFURL>.passUnretained(terminalUrl)

		let folderUrl = simulator.urlForFilePath(filePath)
		let unmanagedFolderUrl = Unmanaged<CFArray>.passRetained([folderUrl] as CFArray)

		let launchSpec = LSLaunchURLSpec(appURL: unmanagedTerminalUrl, itemURLs: unmanagedFolderUrl, passThruParams: nil, launchFlags: [], asyncRefCon: nil)

		withUnsafePointer(to: launchSpec) { (pointer: UnsafePointer<LSLaunchURLSpec>) -> Void in
			LSOpenFromURLSpec(pointer, nil)
		}
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
            .environmentObject(Preferences())
    }
}

extension SimCtl.UI.Appearance {
    var displayName: String {
        rawValue.capitalized
    }
}
