//
//  KeyedEncodingContainer+.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 02/03/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

extension KeyedEncodingContainer where K: CodingKey {
    mutating func encodeIfNotEmpty(_ value: String, forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard value.isNotEmpty else { return }
        try encode(value, forKey: key)
    }

    mutating func encodeIfNotEmpty(_ value: [String], forKey key: KeyedEncodingContainer<K>.Key) throws {
        guard value.count > 0 else { return }
        try encode(value, forKey: key)
    }
}
