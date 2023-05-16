//
//  DeepLinksController.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

/// Loads, manages, and saves the user's collection of deep links
class DeepLinksController: ObservableObject {
    /// The list of links the user has created, sorted however they want.
    @Published private(set) var links: [DeepLink]

    /// The UserDefaults key where we save our links.
    private let defaultsKey = "CRDeepLinks"

    /// Attempts to load saved links from UserDefaults, or creates an empty array otherwise.
    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([DeepLink].self, from: data) {
                links = decoded
                return
            }
        }

        links = []
    }

    /// Writes the user's deep links to UserDefaults.
    private func save() {
        if let encoded = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    /// Creates a new DeepLink instance from a name and URL string.
    /// - Parameters:
    ///   - name: The user's name for this link.
    ///   - url: The stringified URL to load, already prefixed with a schema.
    func create(name: String, url: String) {
        if let verifiedURL = URL(string: url) {
            let link = DeepLink(id: UUID(), name: name, url: verifiedURL)
            links.append(link)
            save()
        }
    }

    /// Deletes a DeepLink instance based on its ID.
    /// - Parameter itemID: The identifier of the link we want to delete.
    func delete(_ itemID: DeepLink.ID?) {
        guard let itemID else { return }

        links.removeAll { link in
            link.id == itemID
        }

        save()
    }

    /// Sorts the user's deep links using name or URL, then saves that order so it takes
    /// effect everywhere deep links are shown.
    /// - Parameter comparator: The sort order to use.
    func sort(using comparator: [KeyPathComparator<DeepLink>]) {
        links.sort(using: comparator)
        save()
    }
}
