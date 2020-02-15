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
        SimCtl.getAppContainer(simulator.udid, appID: bundleID) { url in
            // We can't just "open" the app bundle URL, because
            // macOS will attempt to execute the binary.
            // So, instead we ask macOS to show the Info.plist file,
            // which will be just inside the app bundle.
            if let infoPlist = url?.appendingPathComponent("Info.plist") {
                NSWorkspace.shared.activateFileViewerSelecting([infoPlist])
            }
        }
    }

    /// Sends a JSON string to the device as push notification,
    func sendPushNotification() {
        // save their message for next time
        UserDefaults.standard.set(self.pushPayload, forKey: Defaults.pushPayload)
        SimCtl.sendPushNotification(simulator.udid, appID: bundleID, jsonPayload: pushPayload)
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        SimCtl.uninstall(simulator.udid, appID: bundleID)
    }

    /// Wrtes the user's URL to UserDefaults.
    func saveAppURL() {
        UserDefaults.standard.set(self.url, forKey: Defaults.appURL)
    }

    /// Opens a URL in the appropriate device app.
    func openURL() {
        saveAppURL()
        SimCtl.openURL(simulator.udid, URL: url)
    }

    /// Grants some type of permission to the app.
    func grantPrivacy() {
        SimCtl.grantPermission(simulator.udid, appID: bundleID, permission: resetPermission)
    }

    /// Revokes some type of permission from the app.
    func revokePrivacy() {
        SimCtl.revokePermission(simulator.udid, appID: bundleID, permission: resetPermission)
    }

    /// Resets some type of permission to the app, so it will be asked for again.
    func resetPrivacy() {
        SimCtl.resetPermission(simulator.udid, appID: bundleID, permission: resetPermission)
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(simulator: .example)
    }
}
