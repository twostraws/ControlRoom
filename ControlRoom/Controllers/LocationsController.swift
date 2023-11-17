//
//  LocationsController.swift
//  ControlRoom
//
//  Created by Alexander Chekel on 17.11.2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

class LocationsController: ObservableObject {
    @Published private(set) var locations: [Location]

    private let defaultsKey = "CRSavedLocations"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([Location].self, from: data) {
                locations = decoded
                return
            }
        }

        locations = []
    }

    func create(name: String, latitude: Double, longitude: Double) {
        let location = Location(id: UUID(), name: name, latitude: latitude, longitude: longitude)
        locations.append(location)
        save()
    }

    func delete(_ itemID: Location.ID?) {
        guard let itemID else { return }

        locations.removeAll { location in
            location.id == itemID
        }

        save()
    }

    func sort(using comparator: [KeyPathComparator<Location>]) {
        locations.sort(using: comparator)
        save()
    }

    func item(with itemID: Location.ID?) -> Location? {
        guard let itemID else { return nil }

        return locations.first { location in
            location.id == itemID
        }
    }

    /// Writes the user's deep links to UserDefaults.
    private func save() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
}
