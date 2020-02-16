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
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var window: NSWindow!

    /// One shared `SimulatorsController` to fetch and filter simulator data only once.
    let controller = SimulatorsController()

    var defaultsObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = MainView(controller: controller)

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.title = "Control Room"
        window.isMovableByWindowBackground = true

        UserDefaults.standard.register(defaults: [Defaults.wantsFloatingWindow: false])

        defaultsObservation = UserDefaults.standard.observe(\.CRWantsFloatingWindow, options: [.initial, .new]) { [weak self] (defaults, _) in
            guard let self = self else { return }
            self.window.level = defaults.CRWantsFloatingWindow ? .floating : .normal
        }
    }

    @IBAction func newSimulator(_ sender: Any) {
        controller.showCreateSimulatorPanel = true
    }

    deinit {
        defaultsObservation?.invalidate()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(newSimulator(_:)) {
            return controller.loadingStatus == .success
        }

        return false
    }

}
