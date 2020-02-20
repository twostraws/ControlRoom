//
//  MainWindowController.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import Combine
import SwiftUI

class MainWindowController: NSWindowController {

    // Without this, AppKit won't call -loadWindow
    override var windowNibName: NSNib.Name? { "None" }

    lazy var preferences: Preferences = Preferences()
    lazy var controller: SimulatorsController = SimulatorsController(preferences: preferences)

    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func windowContent() -> some View {
        MainView(controller: controller)
            .environmentObject(preferences)
            .environmentObject(UIState.shared)
    }

    override func loadWindow() {
        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: windowContent())
        window.title = "Control Room"
        window.isMovableByWindowBackground = true

        self.window = window
        adjustWindowLevel()

        // note this is a DID change publisher, not a WILL change publisher
        preferences.objectDidChange.sink(receiveValue: { [weak self] in
            self?.adjustWindowLevel()
        }).store(in: &cancellables)
    }

    private func adjustWindowLevel() {
        window?.level = preferences.wantsFloatingWindow ? .floating : .normal
    }

    @IBAction func toggleFloatingWindow(_ sender: Any) {
        preferences.wantsFloatingWindow.toggle()
    }

    @IBAction func showPreferences(_ sender: Any) {
        UIState.shared.showPreferences = true
    }

}

extension MainWindowController: NSMenuItemValidation {

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleFloatingWindow(_:)) {
            menuItem.state = preferences.wantsFloatingWindow ? .on : .off
            return true
        }

        return responds(to: menuItem.action)
    }

}
