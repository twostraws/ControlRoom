//
//  Contributors.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/19/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Swift

struct Author: Decodable, Identifiable {
    let login: String
    let htmlUrl: URL

    var id: String { login }
}

private struct Contributor: Decodable, Comparable {
    static func < (lhs: Contributor, rhs: Contributor) -> Bool {
        lhs.total < rhs.total
    }

    static func == (lhs: Contributor, rhs: Contributor) -> Bool {
        lhs.author.id == rhs.author.id
    }

    let total: Int
    let author: Author
}

extension Bundle {
    var authors: [Author] {
        guard let fileURL = url(forResource: "contributors", withExtension: "json") else { return [] }
        guard let rawJSON = try? Data(contentsOf: fileURL) else { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let contributors = try? decoder.decode([Contributor].self, from: rawJSON) else { return [] }
        return contributors.sorted().reversed().map(\.author)
    }
}
