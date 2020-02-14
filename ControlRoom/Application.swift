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
    let displayName: String
    let bundleIdentifier: String
    let versionNumber: String
    let buildNumber: String
    let imageURLs: [URL]?
    
    static let `default` = Application()
    
    private init() {
        url = nil
        displayName = ""
        bundleIdentifier = ""
        versionNumber = ""
        buildNumber = ""
        imageURLs = nil
    }
    
    init(url: URL) {
        self.url = url
        let plistURL = url.appendingPathComponent("Info.plist")
        let plistDictionary = NSDictionary(contentsOf: plistURL)
        displayName = Self.fetchAppName(plistDictionary: plistDictionary)
        bundleIdentifier = plistDictionary?["CFBundleIdentifier"] as? String ?? ""
        versionNumber = plistDictionary?["CFBundleShortVersionString"] as? String ?? ""
        buildNumber = plistDictionary?["CFBundleVersion"] as? String ?? ""
        imageURLs = [Self.fetchIconNames(plistDitionary: plistDictionary),
                     Self.fetchIconNames(plistDitionary: plistDictionary, platformIdentifier: "~ipad")]
            .flatMap { $0 }
            .compactMap { Bundle(url: url)?.urlForImageResource($0) }
    }
    
    private static func fetchAppName(plistDictionary: NSDictionary?) -> String {
        plistDictionary?["CFBundleDisplayName"] as? String ?? plistDictionary?["CFBundleName"] as? String ?? ""
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
        iconFilesNames
            .forEach { iconFileName in
                scaleSuffixes
                    .forEach { scaleSuffix in
                        fullIconNames.append(iconFileName+scaleSuffix+platformIdentifier)
                    }
            }
        return fullIconNames
    }
}
