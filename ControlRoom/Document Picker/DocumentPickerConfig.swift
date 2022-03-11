//
//  DocumentPickerConfig.swift
//  ControlRoom
//
//  Created by Manuel Rodriguez on 11/3/22.
//  Copyright © 2022 Paul Hudson. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

struct DocumentPickerConfig {
    let title: String
    let showHiddenFiles: Bool
    let canChooseFiles: Bool
    let canChooseDirectories: Bool
    let allowedContentTypes: [UTType]

    init(title: String = "", showHiddenFiles: Bool = false, canChooseFiles: Bool = true, canChooseDirectories: Bool = false, allowedContentTypes: [UTType]) {
        self.title = title
        self.showHiddenFiles = showHiddenFiles
        self.canChooseFiles = canChooseFiles
        self.canChooseDirectories = canChooseDirectories
        self.allowedContentTypes = allowedContentTypes
    }
}
