//
//  DeepLink.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

struct DeepLink: Identifiable, Codable {
    var id: UUID
    var name: String
    var url: URL
}
