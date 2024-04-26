//
//  SimulatorAction.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import struct SwiftUI.LocalizedStringKey

enum Action: Int, Identifiable {
    case power
    case rename
    case clone
    case delete
    case openRoot

    var id: Int { rawValue }

    var sheetTitle: LocalizedStringKey {
        switch self {
        case .power: ""
        case .rename: "Rename Simulator"
        case .clone: "Clone Simulator"
        case .delete: "Delete Simulator"
        case .openRoot: ""
        }
    }

    var sheetMessage: LocalizedStringKey {
        switch self {
        case .power: ""
        case .rename: "Enter a new name for this simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
        case .clone: "Enter a name for the new simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
        case .delete: "Are you sure you want to delete this simulator? You will not be able to undo this action."
        case .openRoot: ""
        }
    }

    var saveActionTitle: LocalizedStringKey {
        switch self {
        case .power: "Power"
        case .rename: "Rename"
        case .clone: "Clone"
        case .delete: "Delete"
        case .openRoot: ""
        }
    }
}
