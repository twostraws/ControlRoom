//
//  LocalSearchResult.swift
//  ControlRoom
//
//  Created by John McEvoy on 29/11/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation
import MapKit

/// A local search result item
struct LocalSearchResult: Identifiable {
    var id: UUID
    var title: String
    var subtitle: String?
    var completer: MKLocalSearchCompletion?

    init(result: MKLocalSearchCompletion) {
        id = UUID()
        self.title = result.title
        self.subtitle = result.subtitle.clean()
        self.completer = result
    }
}

/// if a string is empty or whitespace, convert it to `nil`
extension String {
    func clean() -> String? {
        let cleanString = self.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanString.isEmpty {
            return nil
        }

        return cleanString
    }
}
