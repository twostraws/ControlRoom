//
//  UTType+Extension.swift
//  ControlRoom
//
//  Created by Manuel Rodriguez on 11/3/22.
//  Copyright © 2022 Paul Hudson. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// Finder file extension allowed
extension UTType {
    static let json = UTType.init(filenameExtension: "json")!
}
