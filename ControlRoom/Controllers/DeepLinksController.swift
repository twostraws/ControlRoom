//
//  DeepLinksController.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

class DeepLinksController: ObservableObject {
    @Published private(set) var links: [DeepLink]
    private let defaultsKey = "CRDeepLinks"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([DeepLink].self, from: data) {
                links = decoded
                return
            }
        }

        links = []
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    func create(name: String, url: String) {
        if let verifiedURL = URL(string: url) {
            let link = DeepLink(id: UUID(), name: name, url: verifiedURL)
            links.append(link)
            save()
        }
    }

    func delete(_ itemID: DeepLink.ID?) {
        guard let itemID else { return }

        links.removeAll { link in
            link.id == itemID
        }

        save()
    }

    func sort(using comparator: [KeyPathComparator<DeepLink>]) {
        links.sort(using: comparator)
        save()
    }
}
