//
//  Constants.swift
//  ControlRoom
//
//  Created by Vinay Jain on 13/02/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

struct Constants {

    private static let pattern = "com\\.apple\\.CoreSimulator\\.SimRuntime\\.([a-zA-Z]+)-([0-9-]+)$"
    static let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
}
