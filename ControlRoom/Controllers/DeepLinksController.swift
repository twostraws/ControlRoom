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

    /// Updates an existing DeepLink with the new name and URL. No changes are made if the `itemID` is `nil`, a matching
    /// DeepLink cannot be found or if the new stringified URL fails construction as a `URL`.
    /// - Parameters:
    ///   - itemID: The identifier of the link that needs to be updated.
    ///   - name: The updated name for this link.
    ///   - url: The updated stringified URL for the deep link.
    func edit(_ itemID: DeepLink.ID?, name: String, url: String) {
        guard
            let itemID,
            let index = links.firstIndex(where: { $0.id == itemID }),
            let verifiedURL = URL(string: url)
        else {
            return
        }

        var link = links[index]
        link.name = name
        link.url = verifiedURL
        links[index] = link

        save()
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

    /// Finds the first deep link matching the desired DeepLink.ID
    /// - Parameter itemID: The identifier to search for.
    /// - Returns: The first matching DeepLink if one is found. Returns `nil` if no matching link is found or if
    /// `itemID` parameter is `nil`.
    func link(_ itemID: DeepLink.ID?) -> DeepLink? {
        guard let itemID else { return nil }

        return links.first(where: { $0.id == itemID })
    }
}
