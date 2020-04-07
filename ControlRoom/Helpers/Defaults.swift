//
//  Defaults.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Constant strings to store our UserDefaults keys for safer access.
enum Defaults {
    /// The app bundle ID the user last worked with.
    static let bundleID = "CRBundleID"

    /// The app URL to open the user last entered.
    static let appURL = "CRAppURL"

    /// The flag that drives the apps filtering mode the user last entered.
    static let shouldDisplaySystemApps = "CRShouldDisplaySystemApps"

    /// The push JSON text the user last entered.
    static let pushPayload = "CRPushPayload"

    /// The cellular operator name the user last entered.
    static let operatorName = "CROperatorName"

    /// Whether the app window is floating or not
    static let wantsFloatingWindow = "CRWantsFloatingWindow"
}

/// Dynamic accessors for KVO
extension UserDefaults {
    // Important: For some reason the property name should match the keyname in order to receive KVO observations
    @objc dynamic var CRWantsFloatingWindow: Bool {
        get { bool(forKey: Defaults.wantsFloatingWindow) }
        set { set(newValue, forKey: Defaults.wantsFloatingWindow) }
    }
}
