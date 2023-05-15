//
//  ChromeRendererTypes.swift
//  ControlRoom
//
//  Created by Paul Hudson on 15/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

/// This file contains all the Decodable types required to work with Apple's property list and JSON
/// files that handle simulator device and chrome data.

import Foundation

struct SimulatorDevice: Decodable {
    var chromeIdentifier: String
    var mainScreenScale: Double
}

struct SimulatorChrome: Decodable {
    var identifier: String
    var images: SimulatorImageSet
    var inputs: [SimulatorImageInput]
}

struct SimulatorImageSet: Decodable {
    var topLeft: String
    var top: String
    var topRight: String
    var right: String
    var bottomRight: String
    var bottom: String
    var bottomLeft: String
    var left: String
    var screen: String
    var sizing: SimulatorImageSetSizing
    var padding: SimulatorSize
    var devicePadding: SimulatorImagePadding
}

struct SimulatorImageSetSizing: Decodable {
    var leftWidth: Double
    var rightWidth: Double
    var topHeight: Double
    var bottomHeight: Double
}

struct SimulatorSize: Decodable {
    var width: Double
    var height: Double
}

// swiftlint:disable identifier_name
struct SimulatorPoint: Decodable {
    var x: Double
    var y: Double
}
// swiftlint:enable identifier_name

struct SimulatorImagePadding: Decodable {
    var top: Double
    var left: Double
    var bottom: Double
    var right: Double
}

struct SimulatorPath: Decodable {
    var insets: SimulatorImagePadding
    var cornerRadiusX: Double
    var cornerRadiusY: Double
}

struct SimulatorImageInput: Decodable {
    var image: String
    var onTop: Bool
    var anchor: String
    var align: String
    var offsets: SimulatorOffsets
}

struct SimulatorOffsets: Decodable {
    var normal: SimulatorPoint
    var rollover: SimulatorPoint
}
