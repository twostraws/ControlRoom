//
//  URLFileAttribute.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 14/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import Foundation

struct URLFileAttribute {
    private(set) var folderSize: Int?
    private(set) var creationDate: Date?
    private(set) var modificationDate: Date?

    init(url: URL) {
        let path = url.path
        guard let dictionary: [FileAttributeKey: Any] = try? FileManager.default
                .attributesOfItem(atPath: path) else {
            return
        }

        if dictionary.keys.contains(FileAttributeKey.creationDate),
            let value = dictionary[FileAttributeKey.creationDate] as? Date {
            self.creationDate = value
        }

        if dictionary.keys.contains(FileAttributeKey.modificationDate),
            let value = dictionary[FileAttributeKey.modificationDate] as? Date {
            self.modificationDate = value
        }
        
        folderSize = getFolderSize(url: url)
    }
    
    private func getFolderSize(url: URL) -> Int {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var size: Int = 0
        for case let fileURL as URL in enumerator {
            guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                continue
            }
            size += fileSize
        }
        return size
    }

}

