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

private struct Contributor: Decodable {
    let total: Int
    let author: Author
}

extension Bundle {

    var authors: [Author]? {
        guard let fileURL = url(forResource: "contributors", withExtension: "json") else { return nil }
        guard let rawJSON = try? Data(contentsOf: fileURL) else { return nil }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let contributors = try? decoder.decode([Contributor].self, from: rawJSON) else { return nil }
        return contributors.sorted(by: { $0.total > $1.total }).map { $0.author }
    }

}
