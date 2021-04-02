//
//  SimulatorAction.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

enum Action: Int, Identifiable {
    case rename
    case clone
    case delete

    var id: Int { rawValue }

    var sheetTitle: String {
        switch self {
        case .rename: return "Rename Simulator"
        case .clone: return "Clone Simulator"
        case .delete: return "Delete Simulator"
        }
    }

    var sheetMessage: String {
        switch self {
        case .rename: return "Enter a new name for this simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
        case .clone: return "Enter a name for the new simulator. It may be the same as the name of an existing simulator, but a unique name will make it easier to identify."
        case .delete: return "Are you sure you want to delete this simulator? You will not be able to undo this action."
        }
    }

    var saveActionTitle: String {
        switch self {
        case .rename: return "Rename"
        case .clone: return "Clone"
        case .delete: return "Delete"
        }
    }
}
