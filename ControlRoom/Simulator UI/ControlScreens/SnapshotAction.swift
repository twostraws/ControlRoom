//
//  SnapshotAction.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 14/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import struct SwiftUI.LocalizedStringKey

enum SnapshotAction: Int, Identifiable {
    case delete
    case rename
    case restore

    var id: Int { rawValue }

    var sheetTitle: LocalizedStringKey {
        switch self {
        case .delete: "Delete Snapshot"
        case .rename: "Rename Snapshot"
        case .restore: "Restore Snapshot"
        }
    }

    var sheetMessage: LocalizedStringKey {
        switch self {
        case .delete: "Are you sure you want to delete this snapshot? You will not be able to undo this action."
        case .rename: "Enter a new name for this snapshot. It must be unique."
        case .restore: "Are you sure you want to restore this snapshot? You will not be able to undo this action."
        }
    }

    var saveActionTitle: LocalizedStringKey {
        switch self {
        case .delete: "Delete"
        case .rename: "Rename"
        case .restore: "Restore"
        }
    }
}
