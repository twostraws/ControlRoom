//
//  PickedColor.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

/// A color struct that can be saved easily and also identified uniquely in SwiftUI.
struct PickedColor: Identifiable, Codable {
    /// A unique identifier, randomly chosen to make this type easier to use with SwiftUI.
    var id: UUID

    /// The underlying NSColor data. We leave this raw to avoid losing accuracy and
    /// avoid dealing with color space issues.
    var data: Data

    /// Dynamically converts our NSColor data back into a real NSColor.
    var nsColor: NSColor {
        if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
            return color
        }

        return .black
    }

    /// The lowercase hex representation of this color, with leading #.
    var hex: String {
        let color = nsColor

        let hexNumber = Int(color.red255) << 16 | Int(color.green255) << 8 | Int(color.blue255)
        return String(format: "#%06x", hexNumber)
    }

    /// The two-digit hex representation of the red channel, without leading #.
    var hexRed: String {
        let color = nsColor

        let hexNumber = Int(color.red255)
        return String(format: "%02x", hexNumber)
    }

    /// The two-digit hex representation of the green channel, without leading #.
    var hexGreen: String {
        let color = nsColor

        let hexNumber = Int(color.green255)
        return String(format: "%02x", hexNumber)
    }

    /// The two-digit hex representation of the blue channel, without leading #.
    var hexBlue: String {
        let color = nsColor

        let hexNumber = Int(color.blue255)
        return String(format: "%02x", hexNumber)
    }

    /// The SwiftUI.Color representation of this PickedColor instance.
    var swiftUIColor: Color {
        Color(nsColor: nsColor)
    }

    /// A sensible default color. Note: using the NSColor.black constant will trigger a crash,
    /// whereas creating black is fine.
    static var `default`: PickedColor? {
        PickedColor(from: NSColor(red: 0, green: 0, blue: 0, alpha: 1))
    }

    /// Creates a new PickedColor with a random identifier and NSColor data.
    init(id: UUID, data: Data) {
        self.id = id
        self.data = data
    }

    /// Creates a new PickedColor with a specific NScolor instance.
    init?(from nsColor: NSColor) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) else { return nil }

        self = PickedColor(id: UUID(), data: data)
    }

    /// Generates the code string required to recreate this color in SwiftUI.
    func swiftUICode(roundedTo places: Int) -> String {
        let color = nsColor
        return "Color(.sRGB, red: \(color.red1.rounded(dp: places)), green: \(color.green1.rounded(dp: places)), blue: \(color.blue1.rounded(dp: places)))"
    }

    /// Generates the code string required to recreate this color in UIKit.
    func uiKitCode(roundedTo places: Int) -> String {
        let color = nsColor
        return "UIColor(displayP3Red: \(color.red1.rounded(dp: places)), green: \(color.green1.rounded(dp: places)), blue: \(color.blue1.rounded(dp: places)), alpha: 1.0)"
    }
}
