//
//  TypeIdentifier.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/12/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import CoreServices

struct TypeIdentifier: Hashable {
    static let anyDevice = TypeIdentifier("public.device")
    static let phone = TypeIdentifier("com.apple.iphone")
    static let pad = TypeIdentifier("com.apple.ipad")
    static let watch = TypeIdentifier("com.apple.watch")
    static let tv = TypeIdentifier("com.apple.apple-tv")

    /// Default type identifiers to be used for unknown simulators
    static let defaultiPhone = TypeIdentifier("com.apple.iphone-11-pro-1")
    static let defaultiPad = TypeIdentifier("com.apple.ipad-pro-12point9-2")
    static let defaultWatch = TypeIdentifier("com.apple.watch-series5-1")
    static let defaultTV = TypeIdentifier("com.apple.apple-tv-4k")

    static func == (lhs: TypeIdentifier, rhs: TypeIdentifier) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    /// The string representation of the Uniform Type Identifier
    let rawValue: String

    /// Private values for extracting metadata about this type identifier
    private let declaration: [String: Any]
    private let bundle: Bundle?
    private var iconFile: String? { declaration[kUTTypeIconFileKey as String] as? String }
    private var iconPath: String? { declaration["_LSIconPath"] as? String }
    private var conformsTo: [TypeIdentifier] {
        let list = (declaration[kUTTypeConformsToKey as String] as? [String]) ?? []
        return list.map(TypeIdentifier.init)
    }

    /// Iterates through this type identifier and all identifiers to which it conforms, looking for one that defines an icon
    private var iconURL: URL? {
        var typesToCheck = [self]
        var checked = Set<TypeIdentifier>()

        while typesToCheck.isNotEmpty {
            let first = typesToCheck.removeFirst()
            guard checked.contains(first) == false else { continue }
            checked.insert(first)

            guard let thisBundle = first.bundle else { continue }

            if let iconName = first.iconFile {
                if let url = thisBundle.url(forResource: iconName, withExtension: nil) ??
                    thisBundle.url(forResource: iconName, withExtension: "icns") {
                    return url
                }
            } else if let iconPath = first.iconPath {
                let fullPath = (thisBundle.bundlePath as NSString).appendingPathComponent(iconPath)
                return URL(fileURLWithPath: fullPath)
            }

            typesToCheck.append(contentsOf: first.conformsTo)
        }

        return nil
    }

    /// Constructs an icon for this type identifier, as defined by its declaration
    var icon: NSImage {
        if let iconURL = iconURL {
            return NSImage(byReferencing: iconURL)
        }

        return NSWorkspace.shared.icon(forFileType: "'ques'")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    func conformsTo(_ other: TypeIdentifier) -> Bool {
        UTTypeConformsTo(rawValue as CFString, other.rawValue as CFString)
    }

    /// Constructs a type identifier from a device model code, such as "iPad8,4"
    init?(modelIdentifier: String) {
        guard let preferred = UTTypeCreatePreferredIdentifierForTag("com.apple.device-model-code" as CFString,
                                                                    modelIdentifier as CFString,
                                                                    "public.device" as CFString) else { return nil }
        let identifier = preferred.takeRetainedValue()
        self.init(identifier as String)
    }

    /// Constructs a type identifier based on its string representation
    init(_ identifier: String) {
        self.rawValue = identifier
        self.declaration = (UTTypeCopyDeclaration(identifier as CFString)?.takeRetainedValue() as? [String: Any]) ?? [:]
        self.bundle = (UTTypeCopyDeclaringBundleURL(identifier as CFString)?.takeRetainedValue()).flatMap { Bundle(url: $0 as URL) }
    }
}
