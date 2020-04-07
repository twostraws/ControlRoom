//
//  Application.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 14/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

struct Application: Hashable {
    let url: URL?
    let type: ApplicationType?
    let displayName: String
    let bundleIdentifier: String
    let versionNumber: String
    let buildNumber: String
    let imageURLs: [URL]?
    let dataFolderURL: URL?
    let bundleURL: URL?

    static let `default` = Application()

    private init() {
        url = nil
        type = nil
        displayName = ""
        bundleIdentifier = ""
        versionNumber = ""
        buildNumber = ""
        imageURLs = nil
        dataFolderURL = nil
        bundleURL = nil
    }

    init?(application: SimCtl.Application) {
        guard let url = URL(string: application.bundlePath) else { return nil }

        self.url = url
        type = application.type
        displayName = application.displayName

        let plistURL = url.appendingPathComponent("Info.plist")
        let plistDictionary = NSDictionary(contentsOf: plistURL)
        bundleIdentifier = application.bundleIdentifier
        versionNumber = plistDictionary?["CFBundleShortVersionString"] as? String ?? ""
        buildNumber = plistDictionary?["CFBundleVersion"] as? String ?? ""

        imageURLs = [Self.fetchIconNames(plistDitionary: plistDictionary),
                     Self.fetchIconNames(plistDitionary: plistDictionary, platformIdentifier: "~ipad")]
            .flatMap { $0 }
            .compactMap { Bundle(url: url)?.urlForImageResource($0) }

        dataFolderURL = URL(string: application.dataFolderPath ?? "")
        bundleURL = URL(string: application.bundlePath)
    }

    private static func fetchIconNames(plistDitionary: NSDictionary?, platformIdentifier: String = "") -> [String] {
        let scaleSuffixes: [String] = ["@2x", "@3x"]
        guard
            let plistDitionary = plistDitionary,
            let iconsDictionary = plistDitionary["CFBundleIcons\(platformIdentifier)"] as? NSDictionary,
            let primaryIconDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? NSDictionary,
            let iconFilesNames = primaryIconDictionary["CFBundleIconFiles"] as? [String]
            else {
                return []
            }

        var fullIconNames = [String]()

        iconFilesNames.forEach { iconFileName in
            scaleSuffixes.forEach { scaleSuffix in
                fullIconNames.append(iconFileName+scaleSuffix+platformIdentifier)
            }
        }

        return fullIconNames
    }
}
