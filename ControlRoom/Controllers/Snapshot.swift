//
//  Snapshot.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 12/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//
import Foundation

struct Snapshot: Equatable, Hashable, Identifiable {
    let id: String
    let creationDate: Date
    let size: Int

    static func == (lhs: Snapshot, rhs: Snapshot) -> Bool {
        lhs.id == rhs.id
    }

    init(id: String, creationDate: Date, size: Int) {
        self.id = id
        self.creationDate = creationDate
        self.size = size
    }
}
