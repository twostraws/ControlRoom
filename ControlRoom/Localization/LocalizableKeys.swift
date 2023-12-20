//
//  LocalizableKeys.swift
//  ControlRoom
//
//  Created by Elliot Knight on 30/11/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

/// Enum representing keys from the Localizable.strings file for localization.
enum LocalizableKeys: String {
    /// Returns: "Alert"
    case alert
    /// Returns: "App"
    case app
    /// Returns: "Aps"
    case aps
    /// Returns:  "(Requires Reboot)"
    case requiresBoot = "requires_reboot"
    /// Returns: "Accessibility Overrides"
    case accessibilityOverrides = "accessibility_overrides"

    /// Retrieves the localized string associated with the enum case.
    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}
