//
//  Simulator.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import CoreServices

/// Stores one simulator and its identifier.
struct Simulator: Identifiable, Comparable, Hashable {
    /// The user-facing name for this simulator, e.g. iPhone 11 Pro Max.
    let name: String

    /// The internal identifier that represents this device.
    let udid: String

    /// Sends back the UDID for Identifiable.
    var id: String { udid }

    /// The uniform type identifier of the simulator device
    let typeIdentifier: TypeIdentifier

    /// The icon representing the simulator's device
    let image: NSImage

    init(name: String, udid: String, typeIdentifier: TypeIdentifier) {
        self.name = name
        self.udid = udid
        self.typeIdentifier = typeIdentifier
        self.image = typeIdentifier.icon ?? TypeIdentifier.defaultiPhone.icon!
    }

    /// Sort simulators alphabetically.
    static func < (lhs: Simulator, rhs: Simulator) -> Bool {
        lhs.name < rhs.name
    }

    /// An example simulator for Xcode preview purposes
    static let example = Simulator(name: "iPhone 11 Pro max", udid: UUID().uuidString, typeIdentifier: .defaultiPhone)

    /// Users whichever simulator simctl feels like; if there's only one active it will be used,
    /// but if there's more than one simctl just picks one.
    static let `default` = Simulator(name: "Default", udid: "booted", typeIdentifier: .defaultiPhone)
}
