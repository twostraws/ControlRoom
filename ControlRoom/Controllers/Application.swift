//
//  Application.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 14/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation
import AppKit

struct Application: Hashable, Comparable {
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

	static func < (lhs: Application, rhs: Application) -> Bool {
		lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
	}

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

        imageURLs = Self.fetchIconName(plistDictionary: plistDictionary)
			.sorted(by: >)
			.compactMap { Bundle(url: url)?.urlForImageResource($0) }

        dataFolderURL = URL(string: application.dataFolderPath ?? "")
        bundleURL = URL(string: application.bundlePath)
    }

	var icon: NSImage? {
		guard let imageURLs = imageURLs else { return nil }

		for iconURL in imageURLs {
			if let iconImage = NSImage(contentsOf: iconURL) {
				return iconImage
			}
		}

		return nil
	}

    private static func fetchIconName(plistDictionary: NSDictionary?) -> [String] {
		guard let plistDictionary = plistDictionary else { return [] }

		var iconFilesNames = iconsList(plistDictionary: plistDictionary)

		if iconFilesNames.isEmpty {
			iconFilesNames = iconsList(plistDictionary: plistDictionary, platformIdentifier: "~ipad")

			// If empty, check for CFBundleIconFiles (since 3.2)
			if iconFilesNames.isEmpty, let iconFiles = plistDictionary["CFBundleIconFiles"] as? [String] {
				iconFilesNames = iconFiles
			}
		}

		if iconFilesNames.isNotEmpty {
			//Search some patterns for primary app icon
			for match in ["76", "60"] {
				let result = iconFilesNames.filter { $0.contains(match) }

				if result.isNotEmpty {
					return result
				}
			}

			return iconFilesNames
		}

		// Check for CFBundleIconFile (legacy, before 3.2)
		if let iconFileName = plistDictionary["CFBundleIconFile"] as? String {
			return [iconFileName]
		}

		return []
    }

	private static func iconsList(plistDictionary: NSDictionary?, platformIdentifier: String = "") -> [String] {
        let scaleSuffixes: [String] = ["@2x", "@3x"]

        guard
            let plistDictionary = plistDictionary,
            let iconsDictionary = plistDictionary["CFBundleIcons\(platformIdentifier)"] as? NSDictionary,
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
