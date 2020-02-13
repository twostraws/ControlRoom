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

    struct DeviceType: Decodable {
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

    struct DeviceList: Decodable {
        let devices: [String: [Device]]
    }

    struct Device: Decodable {
        let status: String?
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
        static let unknown = Runtime(buildversion: "0A000", identifier: "Unknown", version: "0.0.0", isAvailable: false, name: "Unknown OS")
        let buildversion: String
        let identifier: String
        let version: String
        let isAvailable: Bool
        let name: String
    }
}
