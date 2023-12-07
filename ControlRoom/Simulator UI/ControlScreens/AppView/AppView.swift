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

    @AppStorage("CRApps_ShowSystemApps") private var shouldShowSystemApps = true
    @AppStorage("CRApps_LastBundleID") private var lastBundleID = ""
    @AppStorage("CRApps_PushPayload") private var pushPayload = """
    {
        "aps": {
            "alert": {
                "body": "Hello, World!",
                "title": "From Control Room"
            }
        }
    }
    """

    let simulator: Simulator
    let applications: [Application]

    /// The selected application we want to manipulate.
    private var selectedApplication: Application {
        applications.first(where: { $0.bundleIdentifier == lastBundleID })
            ?? .default
    }

    /// The current permission option the user has selected to grant, reset, or revoke.
    @State private var resetPermission: SimCtl.Privacy.Permission = .all

    /// If true shows the uninstall confirmation alert.
    @State private var shouldShowUninstallConfirmationAlert: Bool = false

    init(simulator: Simulator, applications: [Application]) {
        self.simulator = simulator
        self.applications = applications
    }

    var body: some View {
        let apps = applications.filter { $0.type == .user || shouldShowSystemApps }.sorted()
        let selectedApplication = apps.first(where: { $0.bundleIdentifier == lastBundleID }) ?? .default
        let isApplicationSelected = selectedApplication.bundleIdentifier.isNotEmpty

        ScrollView {
            Form {
                Section {
                    HStack {
                        Picker("Application:", selection: $lastBundleID) {
                            ForEach(apps, id: \.bundleIdentifier) { application in
                                Text("\(application.displayName) – \(application.bundleIdentifier)")
                                    .tag(application.bundleIdentifier)
                            }
                        }
                        .pickerStyle(.menu)
                        Toggle("Show system apps", isOn: $shouldShowSystemApps)
                    }

                    HStack {
                        AppSummaryView(application: selectedApplication)
                        Spacer()
                        VStack(alignment: .trailing) {
                            HStack {
                                Button("Launch", action: launchApp)
                                Button("Terminate", action: terminateApp)
                                Button("Restart", action: restartApp)
                                Button("Uninstall", action: confirmDeleteApp)
                            }
                            .disabled(selectedApplication == .default)

                            Menu {
                                Button("Open data folder", action: openDataFolder)
                                    .disabled(selectedApplication.dataFolderURL == nil)
                                Button("Open first app group folder", action: openFirstAppGroupFolder)
                                    .disabled(selectedApplication.firstAppGroupFolderURL == nil)
                                Button("Open app bundle", action: openAppBundle)
                                    .disabled(selectedApplication.bundleURL == nil)

                                Button("Edit UserDefaults", action: editUserDefaults)
                                    .disabled(selectedApplication.dataFolderURL == nil)

                                Divider()

                                Button("Clear Restoration State", action: clearRestorationState)
                                    .disabled(selectedApplication.dataFolderURL == nil)
                                    .help("Removes any saved state restoration data, such as @SceneStorage properties used by the app.")
                            } label: {
                                Label("App Data", systemImage: "square.and.pencil")
                            }
                            .frame(maxWidth: 250)
                        }
                    }
                }

                Spacer()
                    .frame(height: 40)

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
                }
                .disabled(!isApplicationSelected)

                Spacer()
                    .frame(height: 40)

                VStack {
                    TextEditor(text: $pushPayload)
                        .font(.system(.body, design: .monospaced))
                        .disableAutocorrection(true)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(5)
                        .background(.quaternary)
                        .border(.tertiary, width: 1)

                    HStack(spacing: 10) {
                        Button("Select Templates", action: openNotificationTemplate)
                        Spacer()
                        Button("Open Editor", action: openNotificationEditor)
                        Button("Send Push", action: sendPushNotification)
                    }
                }
                .disabled(!isApplicationSelected)
            }
            .padding()
        }
        .tabItem {
            Text("App")
        }
        .alert(isPresented: $shouldShowUninstallConfirmationAlert) {
            Alert(title: Text("Are you sure you want to permanently delete \(selectedApplication.displayName)"),
                  message: Text("You can’t undo this action."),
                  primaryButton: .destructive(Text("Delete the app"), action: uninstallApp),
                  secondaryButton: .default(Text("Cancel")))
        }
    }

    /// Launches the currently selected app.
    func launchApp() {
        SimCtl.launch(simulator.udid, appID: lastBundleID)
    }

    /// Terminates the currently selected app.
    func terminateApp() {
        SimCtl.terminate(simulator.udid, appID: lastBundleID)
    }

    /// Terminates the currently selected app, then restarts it immediately.
    func restartApp() {
        SimCtl.restart(simulator.udid, appID: lastBundleID)
    }

    /// Reveals the app's container directory in Finder.
    func openDataFolder() {
        guard let dataFolderURL = selectedApplication.dataFolderURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([dataFolderURL])
    }

    /// Reveals the first app group's container directory in Finder.
    func openFirstAppGroupFolder() {
        guard let firstAppGroupFolderURL = selectedApplication.firstAppGroupFolderURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([firstAppGroupFolderURL])
    }

    /// Reveals the app's bundle directory in Finder.
    func openAppBundle() {
        guard
            let infoPropertyListURL = selectedApplication.bundleURL?.appendingPathComponent("Info.plist")
        else { return }
        NSWorkspace.shared.activateFileViewerSelecting([infoPropertyListURL])
    }

    /// Removes this app's state restoration data
    func clearRestorationState() {
        guard let dataFolderURL = selectedApplication.dataFolderURL else { return }

        let library = dataFolderURL.appendingPathComponent("Library")
        let savedAppState = library.appendingPathComponent("Saved Application State")

        try? FileManager.default.removeItem(at: savedAppState)
    }

    /// Shows a confirmation alert asking the user if they are sure they want to delete the selected app.
    func confirmDeleteApp() {
        shouldShowUninstallConfirmationAlert = true
    }

    /// Open Finder to select notification template
    func openNotificationTemplate() {
        DocumentPicker.show(withConfig: DocumentPickerConfig(allowedContentTypes: [.json])) { selectedFile in
            guard let selectedPayload = String(data: selectedFile, encoding: .utf8) else { return }
            self.pushPayload = selectedPayload
        }
    }

    /// Open the notification editor
    func openNotificationEditor() {
        UIState.shared.currentSheet = .notificationEditor
    }

    /// Sends a JSON string to the device as push notification,
    func sendPushNotification() {
        SimCtl.sendPushNotification(simulator.udid, appID: lastBundleID, jsonPayload: pushPayload)
    }

    /// Removes the identified app from the device.
    func uninstallApp() {
        SimCtl.uninstall(simulator.udid, appID: selectedApplication.bundleIdentifier)
    }

    /// Opens the app's UserDefaults plist file in Xcode.
    func editUserDefaults() {
        guard let dataFolderURL = selectedApplication.dataFolderURL else { return }
        let preferencesURL = dataFolderURL.appendingPathComponent("Library/Preferences")
        let plist = preferencesURL.appendingPathComponent("\(selectedApplication.bundleIdentifier).plist")

        NSWorkspace.shared.open(plist)
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

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(simulator: .example, applications: [])
            .environmentObject(Preferences())
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
            return rawValue.capitalized
        }
    }
}
