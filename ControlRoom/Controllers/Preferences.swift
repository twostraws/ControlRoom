//
//  Preferences.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine
import KeyboardShortcuts
import SwiftUI

final class Preferences: ObservableObject {
    /// For parts of the app that want to observe a particular value directly,
    /// they need a way to be notified AFTER the value has changed.
    let objectDidChange = PassthroughSubject<Void, Never>()

    @AppStorage("CRWantsMenuBarIcon") var wantsMenuBarIcon = true
    @AppStorage("CRWantsFloatingWindow") var wantsFloatingWindow = false

    @AppStorage("CRSidebar_ShowDefaultSimulator") var showDefaultSimulator = true
    @AppStorage("CRSidebar_ShowBootedDevicesFirst") var showBootedDevicesFirst = true
    @AppStorage("CRSidebar_ShowOnlyActiveDevices") var shouldShowOnlyActiveDevices = false

    @AppStorage("CRTerminalAppPath") var terminalAppPath = "/System/Applications/Utilities/Terminal.app"
}
