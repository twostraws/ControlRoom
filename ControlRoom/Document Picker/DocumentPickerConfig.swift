//
//  DocumentPickerConfig.swift
//  ControlRoom
//
//  Created by Manuel Rodriguez on 11/3/22.
//  Copyright © 2022 Paul Hudson. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// Finder dialog configuration to select file/s
struct DocumentPickerConfig {

    let showHiddenFiles: Bool
    let canChooseFiles: Bool
    let canChooseDirectories: Bool
    let allowedContentTypes: [UTType]

    init(showHiddenFiles: Bool = false, canChooseFiles: Bool = true, canChooseDirectories: Bool = false, allowedContentTypes: [UTType]) {
        self.showHiddenFiles = showHiddenFiles
        self.canChooseFiles = canChooseFiles
        self.canChooseDirectories = canChooseDirectories
        self.allowedContentTypes = allowedContentTypes
    }
}
