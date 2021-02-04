//
//  AppDelegate.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import KeyboardShortcuts
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var mainWindow: MainWindowController = MainWindowController()

    var menuBarItem: NSStatusItem!

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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainWindow.showWindow(self)

        if wantsMenuBarIcon {
            addMenuBarItem()
        }

        KeyboardShortcuts.onKeyUp(for: .resendLastPushNotification) { [weak self] in
            self?.resendLastPushNotification()
        }

        KeyboardShortcuts.onKeyUp(for: .restartLastSelectedApp) { [weak self] in
            self?.restartLastSelectedApp()
        }

        KeyboardShortcuts.onKeyUp(for: .reopenLastURL) { [weak self] in
            self?.reopenLastURL()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @IBAction func orderFrontStandardAboutPanel(_ sender: Any?) {
        let authors = Bundle.main.authors

        if authors.isNotEmpty {
            let content = NSViewController()
            content.title = "Control Room"
            let view = NSHostingView(rootView: AboutView(authors: authors))
            view.frame.size = view.fittingSize
            content.view = view
            let panel = NSPanel(contentViewController: content)
            panel.styleMask = [.closable, .titled]
            panel.orderFront(sender)
            panel.makeKey()
        } else {
            NSApp.orderFrontStandardAboutPanel(sender)
        }
    }

    func addMenuBarItem() {
        menuBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBarItem.button?.image = NSImage(named: NSImage.smartBadgeTemplateName)
        menuBarItem.menu = NSMenu()

        let resend = NSMenuItem(title: "Resend last push notification", action: #selector(resendLastPushNotification), keyEquivalent: "")
        resend.setShortcut(for: .resendLastPushNotification)
        menuBarItem.menu?.addItem(resend)

        let restart = NSMenuItem(title: "Restart last selected app", action: #selector(restartLastSelectedApp), keyEquivalent: "")
        restart.setShortcut(for: .restartLastSelectedApp)
        menuBarItem.menu?.addItem(restart)

        let reopen = NSMenuItem(title: "Reopen last URL", action: #selector(reopenLastURL), keyEquivalent: "")
        reopen.setShortcut(for: .reopenLastURL)
        menuBarItem.menu?.addItem(reopen)
    }

    func removeMenuBarItem() {
        guard menuBarItem != nil else { return }
        NSStatusBar.system.removeStatusItem(menuBarItem)
    }

    @objc func resendLastPushNotification() {
        SimCtl.sendPushNotification(lastSimulatorUDID, appID: lastBundleID, jsonPayload: pushPayload)
    }

    @objc func restartLastSelectedApp() {
        SimCtl.restart(lastSimulatorUDID, appID: lastBundleID)
    }

    @objc func reopenLastURL() {
        SimCtl.openURL(lastSimulatorUDID, URL: lastOpenURL)
    }
}
