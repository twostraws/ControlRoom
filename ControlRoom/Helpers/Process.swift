//
//  Process.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/14/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

extension Process {
    @objc static func execute(_ command: String, arguments: [String]) -> Data? {
        Self.execute(command, arguments: arguments, environmentOverrides: nil)
    }

    static func execute(_ command: String, arguments: [String], environmentOverrides: [String: String]? = nil) -> Data? {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        if let environmentOverrides {
            var environment = ProcessInfo.processInfo.environment
            environment.merge(environmentOverrides) { (_, new) in new }
            task.environment = environment
        }

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return data
        } catch {
            return nil
        }
    }
}
