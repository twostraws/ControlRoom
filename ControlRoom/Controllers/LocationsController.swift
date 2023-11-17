//
//  LocationsController.swift
//  ControlRoom
//
//  Created by Alexander Chekel on 17.11.2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

/// Loads, manages, and saves the user's collection of saved locations.
class LocationsController: ObservableObject {
    /// The list of saved locations the user has created.
    @Published private(set) var locations: [Location]

    /// The UserDefaults key where we save locations.
    private let defaultsKey = "CRSavedLocations"

    /// Attempts to load saved locations from UserDefaults, or creates an empty array otherwise.
    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([Location].self, from: data) {
                locations = decoded
                return
            }
        }

        locations = []
    }

    /// Creates a new Location instance from name, latitude, and longitude.
    /// - Parameters:
    ///   - name: The user's name for this location.
    ///   - latitude: Latitude.
    ///   - longitude: Longitude.
    func create(name: String, latitude: Double, longitude: Double) {
        let location = Location(id: UUID(), name: name, latitude: latitude, longitude: longitude)
        locations.append(location)
        save()
    }

    /// Deletes a Location instance based on its ID.
    /// - Parameter itemID: The identifier of the location we want to delete.
    func delete(_ itemID: Location.ID?) {
        guard let itemID else { return }

        locations.removeAll { location in
            location.id == itemID
        }

        save()
    }

    /// Returns a Location instance based on its ID.
    /// - Parameter itemID: The identifier of the location we want to return.
    /// - Returns: The Location instance with the request ID, if it could be found.
    func item(with itemID: Location.ID?) -> Location? {
        guard let itemID else { return nil }

        return locations.first { location in
            location.id == itemID
        }
    }

    /// Writes the user's saved locations to UserDefaults.
    private func save() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
}
