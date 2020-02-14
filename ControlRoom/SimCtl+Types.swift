//
//  SimCtl+Types.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/13/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

extension SimCtl {

    struct DeviceTypeList: Decodable {
        let devicetypes: [DeviceType]
    }

    struct DeviceType: Decodable, Hashable {
        let bundlePath: String
        let name: String
        let identifier: String

        var modelTypeIdentifier: TypeIdentifier? {
            guard let bundle = Bundle(path: bundlePath) else { return nil }
            guard let plist = bundle.url(forResource: "profile", withExtension: "plist") else { return nil }
            guard let contents = NSDictionary(contentsOf: plist) else { return nil }
            guard let modelIdentifier = contents.object(forKey: "modelIdentifier") as? String else { return nil }

            return TypeIdentifier(modelIdentifier: modelIdentifier)
        }
    }

    struct DeviceList: Decodable, Equatable {
        let devices: [String: [Device]]
    }

    struct Device: Decodable, Equatable {
        let state: String?
        let isAvailable: Bool
        let name: String
        let udid: String
        let deviceTypeIdentifier: String?
        let dataPath: String?
    }

    struct RuntimeList: Decodable {
        let runtimes: [Runtime]
    }

    struct Runtime: Decodable, Hashable {
        static let unknown = Runtime(buildversion: "", identifier: "Unknown", version: "0.0.0", isAvailable: false, name: "Default OS")
        static let runtimeRegex = try? NSRegularExpression(pattern: #"^com\.apple\.CoreSimulator\.SimRuntime\.([a-z]+)-([0-9-]+)$"#, options: .caseInsensitive)

        let buildversion: String
        let identifier: String
        let version: String
        let isAvailable: Bool
        let name: String

        /// The user-visible description of the runtime
        var description: String {
            if buildversion.isEmpty == false {
                return "\(name) (\(buildversion))"
            } else {
                return "\(name)"
            }
        }

        init(buildversion: String, identifier: String, version: String, isAvailable: Bool, name: String) {
            self.buildversion = buildversion
            self.identifier = identifier
            self.version = version
            self.isAvailable = isAvailable
            self.name = name
        }

        init?(runtimeIdentifier: String) {
            guard let match = Runtime.runtimeRegex?.firstMatch(in: runtimeIdentifier, options: [.anchored], range: NSRange(location: 0, length: runtimeIdentifier.utf16.count)) else {
                return nil
            }
            let nsIdentifier = runtimeIdentifier as NSString
            let os = nsIdentifier.substring(with: match.range(at: 1))
            let version = nsIdentifier.substring(with: match.range(at: 2)).replacingOccurrences(of: "_", with: ".")

            self.buildversion = ""
            self.identifier = runtimeIdentifier
            self.version = version
            self.name = "\(os) \(version)"
            self.isAvailable = false
        }
    }
}
