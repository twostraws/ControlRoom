//
//  AppView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Controls features relating to one specific app.
struct AppView: View {
    var simulator: Simulator
    
    /// The selected application we want to manipulate.
    @State private var selectedApplication: Application = .default

    /// The current permission option the user has selected to grant, reset, or revoke.
    @State private var resetPermission = "All"

    /// The URL to open inside the device.
    @State private var url: String = UserDefaults.standard.string(forKey: Defaults.appURL) ?? ""

    /// Push message JSON to be sent to the app.
    @State private var pushPayload = UserDefaults.standard.string(forKey: Defaults.pushPayload) ?? """
    {
        "aps": {
            "alert": {
                "body": "Hello, World!",
                "title": "From Control Room"
            }
        }
    }
    """

    /// All permission options supported by the simulator.
    let resetPermissions = [
        "All",
        "Calendar",
        "Contacts",
        "Location",
        "Microphone",
        "Motion",
        "Photos",
        "Reminders",
        "Siri"
    ]
    
    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .trailing) {
                        Picker("Application:", selection: $selectedApplication.onChange(storeBundleIdentifier)) {
                            ForEach(simulator.applications, id: \.self) { application in
                                Text(application.bundleIdentifier)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        HStack {
                            Button("Show Container", action: showContainer)
                            Button("Uninstall App", action: uninstallApp)
                        }
                    }
                    AppSummaryView(application: selectedApplication)
                }
            }

            FormSpacer()

            Section {
                HStack {
                    Picker("Permissions:", selection: $resetPermission) {
                        ForEach(resetPermissions, id: \.self) {
                            Text($0)
                        }
                    }

                    Button("Grant", action: grantPrivacy)
                    Button("Revoke", action: revokePrivacy)
                    Button("Reset", action: resetPrivacy)
                }

                HStack {
                    TextField("URL to open", text: $url, onCommit: saveAppURL)
                    Button("Open URL", action: openURL)
                }
            }

            FormSpacer()

            VStack {
                TextView(text: $pushPayload)
                    .frame(minHeight: 150, maxHeight: .infinity)

                HStack {
                    Spacer()
                    Button("Send Push Notification", action: sendPushNotification)
                }
            }

            Spacer()
            
        }
        .tabItem {
            Text("App")
        }
        .padding()
        .onAppear {
            self.restoreSelectApplicationIfNeeded()
        }
    }

    /// Reveals the app's container directory in Finder,
    func showContainer() {
        Command.simctl("get_app_container", self.simulator.udid, self.selectedApplication.bundleIdentifier) { result in
            if let data = try? result.get() {
                // We can't just "open" the app bundle URL, because
                // macOS will attempt to execute the binary.
                // So, instead we ask macOS to show the Info.plist file,
                // which will be just inside the app bundle.
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let url = URL(fileURLWithPath: path).appendingPathComponent("Info.plist")
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        }
    }

    /// Sends a JSON string to the device as push notification,
    func sendPushNotification() {
        // save their message for next time
        UserDefaults.standard.set(self.pushPayload, forKey: Defaults.pushPayload)

        // write the current JSON to a temporary file
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempDirectory.appendingPathComponent("cr_push.json")

        do {
            try self.pushPayload.write(to: fileURL, atomically: true, encoding: .utf8)
            Command.simctl("push", self.simulator.udid, self.selectedApplication.bundleIdentifier, fileURL.path)
        } catch {
            print("Write error for URL: \(fileURL)")
        }
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        Command.simctl("uninstall", self.simulator.udid, self.selectedApplication.bundleIdentifier)
    }

    /// Wrtes the user's URL to UserDefaults.
    func saveAppURL() {
        UserDefaults.standard.set(self.url, forKey: Defaults.appURL)
    }

    /// Opens a URL in the appropriate device app.
    func openURL() {
        saveAppURL()
        Command.simctl("openurl", self.simulator.udid, self.url)
    }

    /// Grants some type of permission to the app.
    func grantPrivacy() {
        Command.simctl("privacy", self.simulator.udid, "grant", self.resetPermission.lowercased(), self.selectedApplication.bundleIdentifier)
    }

    /// Revokes some type of permission from the app.
    func revokePrivacy() {
        Command.simctl("privacy", self.simulator.udid, "revoke", self.resetPermission.lowercased(), self.selectedApplication.bundleIdentifier)
    }

    /// Resets some type of permission to the app, so it will be asked for again.
    func resetPrivacy() {
        Command.simctl("privacy", self.simulator.udid, "reset", self.resetPermission.lowercased(), self.selectedApplication.bundleIdentifier)
    }
    
    private func storeBundleIdentifier() {
        UserDefaults.standard.set(selectedApplication.bundleIdentifier, forKey: Defaults.bundleID)
    }
    
    private func restoreSelectApplicationIfNeeded() {
        guard
            let storedBundlerIdentifier = UserDefaults.standard.string(forKey: Defaults.bundleID),
            let selectedApplication = simulator.applications.first(where: { $0.bundleIdentifier == storedBundlerIdentifier })
            else { return }
        self.selectedApplication = selectedApplication
    }
}

private struct AppSummaryView: View {
    
    let application: Application
    
    var body: some View {
        HStack {
            application.imageURLs?.last
                .flatMap(NSImage.init)
                .flatMap(Image.init)?
                .resizable()
                .cornerRadius(5)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading) {
                Text(application.displayName)
                    .font(.headline)
                Text(application.versionNumber)
                    .font(.caption)
                Text(application.buildNumber)
                    .font(.caption)
            }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(simulator: .example)
    }
}
