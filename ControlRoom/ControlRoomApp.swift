//
//  ControlRoomApp.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import KeyboardShortcuts
import SwiftUI

@main
struct ControlRoomApp: App {
    @AppStorage("CRWantsMenuBarIcon") private var wantsMenuBarIcon = true
    @AppStorage("CRApps_LastOpenURL") private var lastOpenURL = ""
    @AppStorage("CRApps_LastBundleID") private var lastBundleID = ""
    @AppStorage("CRLastSimulatorUDID") private var lastSimulatorUDID = "booted"
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

    @StateObject var preferences: Preferences
    @StateObject var controller: SimulatorsController
    @StateObject var deepLinks = DeepLinksController()

    var body: some Scene {
        Window("Control Room", id: "main") {
            MainView(controller: controller)
                .environmentObject(preferences)
                .environmentObject(UIState.shared)
                .environmentObject(deepLinks)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Control Room") {
                    let authors = Bundle.main.authors

                    if authors.isNotEmpty {
                        let content = NSViewController()
                        content.title = "Control Room"
                        let view = NSHostingView(rootView: AboutView(authors: authors))
                        view.frame.size = view.fittingSize
                        content.view = view
                        let panel = NSPanel(contentViewController: content)
                        panel.styleMask = [.closable, .titled]
                        panel.orderFront(nil)
                        panel.makeKey()
                    } else {
                        NSApp.orderFrontStandardAboutPanel(nil)
                    }
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(preferences)
        }

        MenuBarExtra(isInserted: .constant(preferences.wantsMenuBarIcon)) {
            if deepLinks.links.isEmpty == false {
                Menu("Saved deep links") {
                    ForEach(deepLinks.links) { link in
                        Button(link.name) {
                            open(link)
                        }
                    }
                }

                Divider()
            }

            Button("Resend last push notification", action: resendLastPushNotification)
                .keyboardShortcut("p", modifiers: [.control, .option, .command])
            Button("Restart last selected app", action: restartLastSelectedApp)
                .keyboardShortcut("r", modifiers: [.control, .option, .command])
            Button("Reopen last URL", action: reopenLastURL)
                .keyboardShortcut("u", modifiers: [.control, .option, .command])
        } label: {
            Label("Control Room", systemImage: "gear")

        }
    }

    init() {
        let preferences = Preferences()
        _preferences = StateObject(wrappedValue: preferences)
        _controller =  StateObject(wrappedValue: SimulatorsController(preferences: preferences))
    }

    func resendLastPushNotification() {
        SimCtl.sendPushNotification(lastSimulatorUDID, appID: lastBundleID, jsonPayload: pushPayload)
    }

    func restartLastSelectedApp() {
        SimCtl.restart(lastSimulatorUDID, appID: lastBundleID)
    }

    func reopenLastURL() {
        SimCtl.openURL(lastSimulatorUDID, URL: lastOpenURL)
    }

    func open(_ link: DeepLink) {
        SimCtl.openURL(lastSimulatorUDID, URL: link.url.absoluteString)
    }
}
