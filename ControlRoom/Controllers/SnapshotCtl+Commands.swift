//
//  Command.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 12/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import Foundation

extension SnapshotCtl {

    struct Command: CommandLineCommand {
        static let snapshotsFolder: String = ".snapshots"

        var command: String?
        let arguments: [String]
        let environmentOverrides: [String: String]?

        private init(_ command: String, arguments: [String], environmentOverrides: [String: String]? = nil) {
            self.command = command
            self.arguments = arguments
            self.environmentOverrides = environmentOverrides
        }

        static func createSnapshotTree(deviceId: String, snapshotName: String) -> Command {
            Command("/bin/mkdir", arguments: ["-p", "\(devicesPath)/\(snapshotsFolder)/\(deviceId)/\(snapshotName)"])
        }

        /// Open app
        static func open(app: String) -> Command {
            Command("/usr/bin/open", arguments: ["-a", app])
        }
    }

}
