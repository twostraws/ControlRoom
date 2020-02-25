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
    @EnvironmentObject var preferences: Preferences

    var simulator: Simulator
    var applications: [Application]

    /// The selected application we want to manipulate.
    private var selectedApplication: Application {
        return applications.first(where: { $0.bundleIdentifier == preferences.lastBundleID })
            ?? .default
    }

    /// The current permission option the user has selected to grant, reset, or revoke.
    @State private var resetPermission: SimCtl.Privacy.Permission = .all

    /// If true shows the uninstall confirmation alert.
    @State private var shouldShowUninstallConfirmationAlert: Bool = false

    private var isApplicationSelected: Bool {
        !selectedApplication.bundleIdentifier.isEmpty
    }

    init(simulator: Simulator, applications: [Application]) {
        self.simulator = simulator
        self.applications = applications
    }

    var body: some View {
        let apps = applications.filter({ $0.type == .user || preferences.shouldShowSystemApps })

        return Form {
            Section {
                HStack {
                    VStack(alignment: .trailing) {
                        Picker("Application:", selection: $preferences.lastBundleID) {
                            ForEach(apps, id: \.bundleIdentifier) { application in
                                Text(application.bundleIdentifier)
                                    .tag(application.bundleIdentifier)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        HStack {
                            Toggle("Show system apps", isOn: $preferences.shouldShowSystemApps)
                            Button("Show Container", action: showContainer)
                            Button("Uninstall App") { self.shouldShowUninstallConfirmationAlert = true }
                        }
                        .disabled(!isApplicationSelected)
                    }
                    AppSummaryView(application: selectedApplication)
                }
            }

            FormSpacer()

            Section {
                HStack {
                    Picker("Permissions:", selection: $resetPermission) {
                        ForEach(SimCtl.Privacy.Permission.allCases, id: \.self) {
                            Text($0.displayName)
                        }
                    }

                    Button("Grant", action: grantPrivacy)
                    Button("Revoke", action: revokePrivacy)
                    Button("Reset", action: resetPrivacy)
                }

                HStack {
                    TextField("URL to open", text: $preferences.lastOpenURL)
                    Button("Open URL", action: openURL)
                }
            }

            FormSpacer()

            VStack {
                TextView(text: $preferences.pushPayload)
                    .frame(minHeight: 150, maxHeight: .infinity)

                HStack {
                    Spacer()
                    Button("Send Push Notification", action: sendPushNotification)
                        .disabled(!isApplicationSelected)
                }
            }

            Spacer()

        }
        .tabItem {
            Text("App")
        }
        .padding()
        .alert(isPresented: $shouldShowUninstallConfirmationAlert) {
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
        SimCtl.sendPushNotification(simulator.udid, appID: preferences.lastBundleID, jsonPayload: preferences.pushPayload)
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        SimCtl.uninstall(simulator.udid, appID: selectedApplication.bundleIdentifier)
    }

    /// Opens a URL in the appropriate device app.
    func openURL() {
        SimCtl.openURL(simulator.udid, URL: preferences.lastOpenURL)
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

extension SimCtl.Privacy.Permission {
    var displayName: String {
        switch self {
        case .contactsLimited:
            return "Contacts Limited"
        case .locationAlways:
            return "Location Always"
        case .mediaLibrary:
            return "Media Library"
        case .photosAdd:
            return "Photos Add"
        default:
            return self.rawValue.capitalized
        }
    }
}
