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
    var applications: [Application]

    /// The selected application we want to manipulate.
    @State private var selectedApplication: Application = .default

    /// If true shows also system apps
    @State private var shouldDisplaySystemApps = UserDefaults.standard.bool(forKey: Defaults.shouldDisplaySystemApps)

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

    /// If true shows the unistall confirmation alert.
    @State private var shouldShowUnistallConfirmationAlert: Bool = false

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

    init(simulator: Simulator, applications: [Application]) {
        self.simulator = simulator
        self.applications = applications
        loadStoredSettings()
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .trailing) {
                        Picker("Application:", selection: $selectedApplication.onChange(storeBundleIdentifier)) {
                            ForEach(applications.filter({ $0.type == .user || shouldDisplaySystemApps }), id: \.self) { application in
                                Text(application.bundleIdentifier)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        HStack {
                            Toggle("Show system apps", isOn: $shouldDisplaySystemApps.onChange(storeShouldShouldShowSystemApps))
                            Button("Show Container", action: showContainer)
                            Button("Uninstall App") { self.shouldShowUnistallConfirmationAlert = true }
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
        .alert(isPresented: $shouldShowUnistallConfirmationAlert) {
            Alert(title: Text("Are you sure you want to permanently delete \(selectedApplication.displayName)"),
                  message: Text("You can’t undo this action."),
                  primaryButton: .destructive(Text("Delete the app"), action: uninstallApp),
                  secondaryButton: .default(Text("Cancel")))
        }
    }

    /// Reveals the app's container directory in Finder,
    func showContainer() {
        SimCtl.getAppContainer(simulator.udid, appID: selectedApplication.bundleIdentifier) { url in
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
        SimCtl.sendPushNotification(simulator.udid, appID: selectedApplication.bundleIdentifier, jsonPayload: pushPayload)
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        SimCtl.uninstall(simulator.udid, appID: selectedApplication.bundleIdentifier)
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
        SimCtl.grantPermission(simulator.udid, appID: selectedApplication.bundleIdentifier, permission: resetPermission)
    }

    /// Revokes some type of permission from the app.
    func revokePrivacy() {
        SimCtl.revokePermission(simulator.udid, appID: selectedApplication.bundleIdentifier, permission: resetPermission)
    }

    /// Resets some type of permission to the app, so it will be asked for again.
    func resetPrivacy() {
        SimCtl.resetPermission(simulator.udid, appID: selectedApplication.bundleIdentifier, permission: resetPermission)
    }

    private func storeShouldShouldShowSystemApps() {
        UserDefaults.standard.set(shouldDisplaySystemApps, forKey: Defaults.shouldDisplaySystemApps)
    }

    private func storeBundleIdentifier() {
        UserDefaults.standard.set(selectedApplication.bundleIdentifier, forKey: Defaults.bundleID)
    }

    private func loadStoredSettings() {
        selectedApplication = applications.first(where: { $0.bundleIdentifier == UserDefaults.standard.string(forKey: Defaults.bundleID) }) ?? .default
        shouldDisplaySystemApps = UserDefaults.standard.bool(forKey: Defaults.shouldDisplaySystemApps)
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
        AppView(simulator: .example, applications: [])
    }
}
