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

    /// The current state of logging
    @State private var isLoggingEnabled = false
	@State var dropHovering: Bool = false

    var body: some View {
        ScrollView {
            Form {
                Group {
                    Section {
                        Button("Trigger iCloud Sync", action: triggerSync)
                    }
                    Divider()
                }
                Group {
                    Section(header: Text("Logging")) {
                        HStack {
                            if isLoggingEnabled {
                                Button("Disable Logging", action: updateLogging)
                                Button("Get Logs", action: getLogs)
                            } else if !isLoggingEnabled {
                                Button("Enable Logging", action: updateLogging)
                            }
                        }
                    }
                    Divider()
                }
                Group {
                    Section(header: Text("Copy Pasteboard")) {
                        HStack {
                            Button("Simulator → Mac", action: copyPasteboardToMac)
                            Button("Mac → Simulator", action: copyPasteboardToSim)
                        }
                    }
                    Divider()
                }
                Group {
                    Section(header: Text("Open URL")) {
                        HStack {
                            TextField("URL / deep link to open", text: $lastOpenURL)
                            Button("Open URL", action: openURL)
                        }
                    }
                    Divider()
                    Section(header: Text("Add Root Certificate")) {
                        HStack {
                            TextField("Trusted root certificate file location", text: $lastCertificateFilePath)
                            Button("Add Root Certificate", action: addRootCertificate)
                        }
                    }
                }
                Group {
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
                        Divider()
                    }
                    Spacer()
                    HStack {
                        Button("Reset Keychain", action: resetKeychain)
                        Button("Erase Content and Settings", action: eraseDevice)
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
            SimCtl.setLogging(simulator.udid, enableLogging: false)
            isLoggingEnabled = false
        } else {
            SimCtl.setLogging(simulator.udid, enableLogging: true)
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
		NSWorkspace.shared.activateFileViewerSelecting([simulator.urlForFilePath(filePath)])
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
