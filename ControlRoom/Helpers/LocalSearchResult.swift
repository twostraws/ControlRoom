//
//  LocalSearchResult.swift
//  ControlRoom
//
//  Created by John McEvoy on 29/11/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation
import MapKit

struct LocalSearchResult: Identifiable {
    var id: UUID
    var title: String
    var subtitle: String?
    var latitude: Double?
    var longitude: Double?
    var completer: MKLocalSearchCompletion?

    init(title: String, subtitle: String?) {
        id = UUID()
        self.title = title
        self.subtitle = subtitle?.clean()
    }

    init(result: MKLocalSearchCompletion) {
        id = UUID()
        self.title = result.title
        self.subtitle = result.subtitle.clean()
        self.completer = result
    }

    func toLocation() -> Location? {
        guard let latitude, let longitude else {
            return nil
        }

        return Location(id: id, name: title, latitude: latitude, longitude: longitude)
    }
}

extension String {
    func clean() -> String? {
        let cleanString = self.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanString.isEmpty {
            return nil
        }

        return cleanString
    }
}
