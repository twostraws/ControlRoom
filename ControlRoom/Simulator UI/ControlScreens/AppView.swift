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
        applications.first(where: { $0.bundleIdentifier == preferences.lastBundleID })
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
		let apps = applications.filter({ $0.type == .user || preferences.shouldShowSystemApps }).sorted()
		let selectedApplication = apps.first(where: { $0.bundleIdentifier == preferences.lastBundleID }) ?? .default
		let isApplicationSelected = selectedApplication.bundleIdentifier.isNotEmpty

        return Form {
            Section {
                HStack {
					Picker("Application:", selection: $preferences.lastBundleID) {
						ForEach(apps, id: \.bundleIdentifier) { application in
							HStack {
								AppIcon(application: application, width: 16)
								Text(application.displayName)
									.frame(minWidth: 150, alignment: .leading)
								Text(application.bundleIdentifier)
									.font(.caption)
							}
							.tag(application.bundleIdentifier)
						}
					}
					.pickerStyle(PopUpButtonPickerStyle())
					Toggle("Show system apps", isOn: $preferences.shouldShowSystemApps)
                }
				HStack {
					AppSummaryView(application: selectedApplication)
					Spacer()
					VStack(alignment: .trailing) {
						HStack {
							Button("Open data folder", action: openDataFolder)
								.disabled(selectedApplication.dataFolderURL == nil)
							Button("Open app bundle", action: openAppBundle)
								.disabled(selectedApplication.bundleURL == nil)
						}
						Button("Uninstall App") { shouldShowUninstallConfirmationAlert = true }
							.disabled(selectedApplication.type != .user)
					}
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
			.disabled(!isApplicationSelected)

            FormSpacer()

            VStack {
                TextEditor(text: $preferences.pushPayload)
                    .frame(minHeight: 150, maxHeight: .infinity)

                HStack(spacing: 10) {
                    Spacer()
                    Button("Open Notification Editor", action: openNotificationEditor)
                    Button("Send Push Notification", action: sendPushNotification)
                }
            }
			.disabled(!isApplicationSelected)

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

    /// Reveals the app's container directory in Finder.
    func openDataFolder() {
        guard
            let dataFolderURL = selectedApplication.dataFolderURL
            else { return }
        NSWorkspace.shared.activateFileViewerSelecting([dataFolderURL])
    }

    /// Reveals the app's bundle directory in Finder.
    func openAppBundle() {
        guard
            let infoPropertyListURL = selectedApplication.bundleURL?.appendingPathComponent("Info.plist")
            else { return }
        NSWorkspace.shared.activateFileViewerSelecting([infoPropertyListURL])
    }

    /// Open the notification editor
    func openNotificationEditor() {
        UIState.shared.currentSheet = .notificationEditor
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

private struct AppIcon: View {

	let application: Application
	let width: CGFloat

    var body: some View {
		if let icon = application.icon {
			Image(nsImage: icon)
				.resizable()
				.cornerRadius(width / 5)
				.frame(width: width, height: width)
        } else {
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: width / 5)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 0.5, dash: [width / 20 + 1]))
                )
                .frame(width: width, height: width)
        }
	}
}

private struct AppSummaryView: View {

    let application: Application

    var body: some View {
        HStack {
            AppIcon(application: application, width: 60)
			VStack(alignment: .leading) {
                Text(application.displayName)
                    .font(.headline)
				Text(application.versionNumber.isNotEmpty ? "Version \(application.versionNumber)" : "")
                    .font(.caption)
				Text(application.buildNumber.isNotEmpty ? "Build \(application.buildNumber)" : "")
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
            return rawValue.capitalized
        }
    }
}
