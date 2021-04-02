//
//  XcodeCommandLineToolsController.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 30/03/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation
import Combine

struct XcodeCommandLineToolsController {
    static func selectedCommandLineTool() -> AnyPublisher<DeveloperTool, Never> {
        Publishers.CombineLatest(SystemProfiler.listDeveloperTools(), XcodeSelect.printPath())
            .replaceError(with: ([], ""))
            .map { devTools, xcodeSelectResult -> DeveloperTool in
                for devTool in devTools {
                    if xcodeSelectResult.contains(devTool.path), devTool.version >= "11.4" {
                        return devTool
                    }
                }
                return .empty
            }
            .eraseToAnyPublisher()
    }

}

private enum XcodeSelect: CommandLineCommandExecuter {
    typealias Error = CommandLineError

    static var launchPath = "/usr/bin/xcode-select"

    static func printPath() -> AnyPublisher<String, XcodeSelect.Error> {
        XcodeSelect.executeSubject(.printPath())
            .compactMap { String(data: $0, encoding: .utf8) }
            .eraseToAnyPublisher()
    }
}

private extension XcodeSelect {
    struct Command: CommandLineCommand {
        let arguments: [String]

        private init(_ subcommand: String, arguments: [String]) {
            self.arguments = [subcommand] + arguments
        }

        /// Print the path of the active developer directory.
        static func printPath() -> Command {
            Command("-p", arguments: [])
        }
    }
}

private enum SystemProfiler: CommandLineCommandExecuter {
    typealias Error = CommandLineError

    static var launchPath = "/usr/sbin/system_profiler"

    static func listDeveloperTools() -> AnyPublisher<[DeveloperTool], SystemProfiler.Error> {
        let publisher: AnyPublisher<SystemProfiler.DeveloperToolsList, SystemProfiler.Error> = SystemProfiler.executeJSON(.listDeveloperTools())
        return publisher
            .map(\.list)
            .eraseToAnyPublisher()
    }
}

private extension SystemProfiler {
    struct Command: CommandLineCommand {
        let arguments: [String]

        private init(_ subcommand: String, arguments: [String]) {
            self.arguments = [subcommand] + arguments
        }

        /// List the available developer tools.
        static func listDeveloperTools() -> Command {
            Command("SPDeveloperToolsDataType", arguments: ["-json"])
        }
    }
}

struct DeveloperTool: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case path = "spdevtools_path"
        case version = "spdevtools_version"
    }

    static let empty = DeveloperTool(path: "", version: "")

    let path: String
    let version: String
}

// swiftlint:disable nesting
extension SystemProfiler {
    struct DeveloperToolsList: Decodable {
        private enum CodingKeys: String, CodingKey {
            case list = "SPDeveloperToolsDataType"
        }

        let list: [DeveloperTool]
    }

}
// swiftlint:enable nesting
