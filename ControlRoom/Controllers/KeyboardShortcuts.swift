//
//  KeyboardShortcuts.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let resendLastPushNotification = Self("resendLastPushNotification", default: .init(.p, modifiers: [.control, .option, .command]))

    static let restartLastSelectedApp = Self("restartLastSelectedApp", default: .init(.r, modifiers: [.control, .option, .command]))

    static let reopenLastURL = Self("reopenLastURL", default: .init(.u, modifiers: [.control, .option, .command]))
}
