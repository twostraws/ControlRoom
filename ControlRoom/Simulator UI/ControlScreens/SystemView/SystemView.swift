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
    @EnvironmentObject var deepLinks: DeepLinksController

    @AppStorage("CRApps_LastOpenURL") private var lastOpenURL = ""
    @AppStorage("CRApps_LastCertificateFilePath") private var lastCertificateFilePath = ""

    /// The current state of logging.
    @State private var isLoggingEnabled = false

    /// Whether the user is currently hovering over the area to copy files.
	@State private var dropHovering: Bool = false

    var body: some View {
        ScrollView {
            Form {
                Section {
                    LabeledContent("Device:") {
                        Text("\(simulator.name) – \(simulator.runtime?.description ?? "Unknown OS")")
                            .textSelection(.enabled)
                    }

                    LabeledContent("Device ID:") {
                        Text(simulator.udid)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 5)

                    LabeledContent("Root path:") {
                        Text(simulator.urlForFilePath(.root).relativePath)
                            .truncationMode(.head)
                            .textSelection(.enabled)
                    }

                    HStack {
                        Spacer()
                        Button("Open in Finder", action: { openInFinder(.root) })
                        Button("Open in Terminal", action: { openInTerminal(.root) })
                    }

                    LabeledContent("Files path:") {
                        VStack(alignment: .leading) {
                            Text(simulator.urlForFilePath(.files).relativePath)
                                .textSelection(.enabled)

                            HStack(alignment: .bottom) {
                                Text(dropHovering ? "Drop to copy" : "Drag files here to copy").font(.caption)
                                Spacer()
                                Button("Open in Finder") { openInFinder(.files) }
                                Button("Open in Terminal") { openInTerminal(.files) }
                            }
                        }
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(dropHovering ? Color.accentColor : Color.gray, lineWidth: 1)
                        )
                        .onDrop(of: [.fileURL], isTargeted: $dropHovering) { providers in
                            return simulator.copyFilesFromProviders(providers, toFilePath: .files)
                        }
                    }
                    .padding(.vertical, 5)
                }

                Spacer()
                    .frame(height: 40)

                HStack {
                    TextField("Open URL:", text: $lastOpenURL, prompt: Text("Enter the URL or deep link you want to open"))
                    Button("Open", action: openURL)
                    Menu("Saved Links") {
                        ForEach(deepLinks.links) { link in
                            Button(link.name) { open(link) }
                        }

                        if deepLinks.links.isEmpty == false {
                            Divider()
                        }

                        Button("Customize…") {
                            UIState.shared.currentSheet = .deepLinkEditor
                        }
                    }
                    .frame(width: 120)
                }

                HStack {
                    TextField("Root certificate:", text: $lastCertificateFilePath, prompt: Text("Enter the full path to a trusted root certificate"))
                    Button("Add", action: addRootCertificate)
                }

                Spacer()
                    .frame(height: 40)

                LabeledContent("Data:") {
                    HStack {
                        Button("Trigger iCloud Sync", action: triggerSync)
                        Button("Reset Keychain", action: resetKeychain)
                        Button("Erase", action: eraseDevice)
                    }
                }

                Group {
                    Section {
                        LabeledContent("Copy pasteboard:") {
                            HStack {
                                Button("Simulator → Mac", action: copyPasteboardToMac)
                                Button("Mac → Simulator", action: copyPasteboardToSim)
                            }
                        }
                    }
                }

                LabeledContent("Logging:") {
                    HStack {
                        if isLoggingEnabled {
                            Button("Disable Logging", action: updateLogging)
                            Button("Get Logs", action: getLogs)
                        } else if !isLoggingEnabled {
                            Button("Enable Logging", action: updateLogging)
                        }
                    }
                }
            }
            .padding()
        }
        .tabItem {
            Text("System")
        }
        .onAppear {
            isLoggingEnabled = UserDefaults.standard.bool(forKey: "\(simulator.udid).logging")
        }
    }

    /// Starts an immediate iCloud sync.
    func triggerSync() {
        SimCtl.triggeriCloudSync(simulator.udid)
    }
    /// Update logging.
    func updateLogging() {
        if isLoggingEnabled {
            SimCtl.setLogging(simulator, enableLogging: false)
            isLoggingEnabled = false
        } else {
            SimCtl.setLogging(simulator, enableLogging: true)
            isLoggingEnabled = true
        }
    }
    /// Get logs.
    func getLogs() {
        SimCtl.getLogs(simulator.udid)
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
		simulator.open(filePath)
	}

	func openInTerminal(_ filePath: Simulator.FilePathKind) {
        guard preferences.terminalAppPath.isNotEmpty else { return }

        let terminalUrl = URL(fileURLWithPath: preferences.terminalAppPath) as CFURL
		let unmanagedTerminalUrl = Unmanaged<CFURL>.passUnretained(terminalUrl)
		let folderUrl = simulator.urlForFilePath(filePath)
		let unmanagedFolderUrl = Unmanaged<CFArray>.passRetained([folderUrl] as CFArray)

		let launchSpec = LSLaunchURLSpec(appURL: unmanagedTerminalUrl, itemURLs: unmanagedFolderUrl, passThruParams: nil, launchFlags: [], asyncRefCon: nil)

		withUnsafePointer(to: launchSpec) { (pointer: UnsafePointer<LSLaunchURLSpec>) -> Void in
			LSOpenFromURLSpec(pointer, nil)
		}
	}

    func open(_ link: DeepLink) {
        SimCtl.openURL(simulator.udid, URL: link.url.absoluteString)
    }
}

struct SystemView_Previews: PreviewProvider {
    static var previews: some View {
		let preferences = Preferences()

		SystemView(simulator: .example)
			.environmentObject(preferences)
    }
}

extension SimCtl.UI.Appearance {
    var displayName: String {
        rawValue.capitalized
    }
}
