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
    enum Platform: CaseIterable {
        case iPhone
        case iPad
        case watch
        case tv

        var displayName: String {
            switch self {
            case .iPhone: return "iPhone"
            case .iPad: return "iPad"
            case .watch: return "Apple Watch"
            case .tv: return "Apple TV"
            }
        }
    }
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

    /// The platform of the simulator
    let platform: Platform

    /// The information about the simulator OS
    let runtime: SimCtl.Runtime?

    init(name: String, udid: String, typeIdentifier: TypeIdentifier, runtime: SimCtl.Runtime?) {
        self.name = name
        self.udid = udid
        self.typeIdentifier = typeIdentifier
        self.image = typeIdentifier.icon
        self.runtime = runtime

        if typeIdentifier.conformsTo(.pad) {
            self.platform = .iPad
        } else if typeIdentifier.conformsTo(.watch) {
            self.platform = .watch
        } else if typeIdentifier.conformsTo(.tv) {
            self.platform = .tv
        } else {
            self.platform = .iPhone
        }
    }

    /// Sort simulators alphabetically.
    static func < (lhs: Simulator, rhs: Simulator) -> Bool {
        lhs.name < rhs.name
    }

    /// An example simulator for Xcode preview purposes
    static let example = Simulator(name: "iPhone 11 Pro max", udid: UUID().uuidString, typeIdentifier: .defaultiPhone, runtime: .unknown)

    /// Users whichever simulator simctl feels like; if there's only one active it will be used,
    /// but if there's more than one simctl just picks one.
    static let `default` = Simulator(name: "Default", udid: "booted", typeIdentifier: .defaultiPhone, runtime: nil)
}
