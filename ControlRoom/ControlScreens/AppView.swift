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

    /// The bundle ID of the app we want to manipulate.
    @State private var bundleID = UserDefaults.standard.string(forKey: Defaults.bundleID) ?? ""

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
                TextField("App Bundle ID", text: $bundleID) {
                    UserDefaults.standard.set(self.bundleID, forKey: Defaults.bundleID)
                }
            }

            Button("Show Container", action: showContainer)

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

            HStack {
                Spacer()
                Button("Uninstall App", action: uninstallApp)
            }
        }
        .tabItem {
            Text("App")
        }
        .padding()
    }

    /// Reveals the app's container directory in Finder,
    func showContainer() {
        Command.simctl("get_app_container", self.simulator.udid, self.bundleID) { result in
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
            Command.simctl("push", self.simulator.udid, self.bundleID, fileURL.path)
        } catch {
            print("Write error for URL: \(fileURL)")
        }
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        Command.simctl("uninstall", self.simulator.udid, self.bundleID)
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
        Command.simctl("privacy", self.simulator.udid, "grant", self.resetPermission.lowercased(), self.bundleID)
    }

    /// Revokes some type of permission from the app.
    func revokePrivacy() {
        Command.simctl("privacy", self.simulator.udid, "revoke", self.resetPermission.lowercased(), self.bundleID)
    }

    /// Resets some type of permission to the app, so it will be asked for again.
    func resetPrivacy() {
        Command.simctl("privacy", self.simulator.udid, "reset", self.resetPermission.lowercased(), self.bundleID)
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(simulator: .example)
    }
}
