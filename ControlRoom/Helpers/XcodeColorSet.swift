//
//  XcodeColorSet.swift
//  ControlRoom
//
//  Created by Paul Hudson on 17/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

// This file describes the file format used by Xcode asset catalog
// color sets. The struct names follow the format of the file, so
// even though some look a little redundant it's what Xcode
// is looking for.
struct XcodeColorSet: Codable {
    var colors: [XcodeColors]
    var info: XcodeColorInfo

    /// A helper initializer to bypass the complexity of the colorset
    /// file structure, because only care about RGB values.
    init(red: String, green: String, blue: String) {
        self = XcodeColorSet(colors: [XcodeColors(color: XcodeColor(components: XcodeColorComponents(alpha: "1.000", blue: "0x\(blue)", green: "0x\(green)", red: "0x\(red)")))], info: XcodeColorInfo())
    }

    /// The default initializer, where both values must be provided.
    private init(colors: [XcodeColors], info: XcodeColorInfo) {
        self.colors = colors
        self.info = info
    }
}

struct XcodeColors: Codable {
    var color: XcodeColor
    var idiom = "universal"
}

struct XcodeColor: Codable {
    var colorSpace = "srgb"
    var components: XcodeColorComponents
}

struct XcodeColorComponents: Codable {
    var alpha: String
    var blue: String
    var green: String
    var red: String
}

struct XcodeColorInfo: Codable {
    var author = "xcode"
    var version = 1
}
