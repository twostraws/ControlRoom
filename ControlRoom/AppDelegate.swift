//
//  AppDelegate.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    lazy var mainWindow: MainWindowController = MainWindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainWindow.showWindow(self)
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

}
