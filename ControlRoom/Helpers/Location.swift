//
//  Location.swift
//  ControlRoom
//
//  Created by Alexander Chekel on 17.11.2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

struct Location: Identifiable, Codable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
}
