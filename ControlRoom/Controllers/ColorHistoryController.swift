//
//  ColorHistoryController.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Loads, manages, and saves the user's collection of picked colors.
class ColorHistoryController: ObservableObject {
    /// The list of colors the user has picked over time.
    @Published private(set) var colors: [PickedColor]

    /// The UserDefaults key where we save our picked colors.
    private let defaultsKey = "CRColorHistory"

    /// Attempts to load saved colors from UserDefaults, or creates an empty array otherwise.
    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([PickedColor].self, from: data) {
                colors = decoded
                return
            }
        }

        colors = []
    }

    /// Writes the user's picked colors to UserDefaults.
    private func save() {
        if let encoded = try? JSONEncoder().encode(colors) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    /// Creates a new PickedColor instance from an NSColor, adds it to the start of the array
    /// so it appears immediately in the UI, then triggers a save.
    /// - Parameters:
    ///   - color: The NSColor we want to create
    /// - Returns: A PickedColor instance if it could be created.
    func add(_ color: NSColor?) -> PickedColor? {
        guard let color else { return nil }
        guard let pickedColor = PickedColor(from: color) else { return nil }

        colors.insert(pickedColor, at: 0)
        save()

        return pickedColor
    }

    /// Deletes a picked color instance based on its ID.
    /// - Parameter itemID: The identifier of the color we want to delete.
    func delete(_ itemID: PickedColor.ID?) {
        guard let itemID else { return }

        colors.removeAll { color in
            color.id == itemID
        }

        save()
    }

    /// Returns a picked color instance based on its ID.
    /// - Parameter itemID: The identifier of the color we want to return.
    /// - Returns: The PickedColor instance with the request ID, if it could be found.
    func item(with itemID: PickedColor.ID?) -> PickedColor? {
        guard let itemID else { return nil }

        return colors.first { color in
            color.id == itemID
        }
    }
}
