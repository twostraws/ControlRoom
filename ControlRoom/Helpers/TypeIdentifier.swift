//
//  TypeIdentifier.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import CoreServices
import UniformTypeIdentifiers

struct TypeIdentifier: Hashable {
    static let anyDevice = TypeIdentifier("public.device")
    static let phone = TypeIdentifier("com.apple.iphone")
    static let pad = TypeIdentifier("com.apple.ipad")
    static let watch = TypeIdentifier("com.apple.watch")
    static let vision = TypeIdentifier("com.apple.vision-pro")

    static let tv = TypeIdentifier("com.apple.apple-tv")

    /// Default type identifiers to be used for unknown simulators
    static let defaultiPhone = TypeIdentifier("com.apple.iphone-11-pro-1")
    static let defaultiPad = TypeIdentifier("com.apple.ipad-pro-12point9-2")
    static let defaultWatch = TypeIdentifier("com.apple.watch-series5-1")
    static let defaultTV = TypeIdentifier("com.apple.apple-tv-4k")
    static let defaultVision = TypeIdentifier("com.apple.vision-pro")

    static func == (lhs: TypeIdentifier, rhs: TypeIdentifier) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    /// The string representation of the Uniform Type Identifier
    let rawValue: String

    /// Constructs an icon for this type identifier, as defined by its declaration
    var icon: NSImage {
        let type = UTType(rawValue) ?? .bundle
        return NSWorkspace.shared.icon(for: type)
    }

    func conformsTo(_ other: TypeIdentifier) -> Bool {
        let ourType = UTType(rawValue) ?? .bundle
        let otherType = UTType(other.rawValue) ?? .bundle
        return ourType.conforms(to: otherType)
    }

    /// Constructs a type identifier from a device model code, such as "iPad8,4"
    init?(modelIdentifier: String) {
        let modelTagClass = UTTagClass(rawValue: "com.apple.device-model-code")
        let conformingTo = UTType("public.device")

        let type = UTType(tag: modelIdentifier, tagClass: modelTagClass, conformingTo: conformingTo)

        let identifier = type?.identifier ?? ""
        self.init(identifier as String)
    }

    /// Constructs a type identifier based on its string representation
    init(_ identifier: String) {
        rawValue = identifier
    }
}
