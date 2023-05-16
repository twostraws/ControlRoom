//
//  DeepLink.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

/// A named URL with a unique identifier to make them work well with SwiftUI.
struct DeepLink: Identifiable, Codable {
    var id: UUID
    var name: String
    var url: URL
}
