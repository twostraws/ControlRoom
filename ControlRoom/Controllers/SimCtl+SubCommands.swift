//
//  SimCtl+SubCommands.swift
//  ControlRoom
//
//  Created by Patrick Luddy on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Foundation

// swiftlint:disable file_length
extension SimCtl {
    struct Command: CommandLineCommand {
        let arguments: [String]

        private init(_ subcommand: String, arguments: [String]) {
            self.arguments = ["simctl", subcommand] + arguments
        }

        /// Create a new device.
        static func create(name: String, deviceTypeId: String, runtimeId: String? = nil) -> Command {
            Command("create", arguments: [name, deviceTypeId])
        }

        /// Clone an existing device.
        static func clone(deviceId: String, name: String) -> Command {
            Command("clone", arguments: [deviceId, name])
        }

        /// Upgrade a device to a newer runtime.
        static func upgrade(deviceId: String, runtimeId: String) -> Command {
            Command("upgrade", arguments: [deviceId, runtimeId])
        }

        /// Delete spcified devices, unavailable devices, or all devices.
        static func delete(_ delete: Delete) -> Command {
            Command("delete", arguments: delete.arguments)
        }

        /// Create a new watch and phone pair.
        static func pair(watch: String, phone: String) -> Command {
            Command("pair", arguments: [watch, phone])
        }

        /// Unpair a watch and phone pair.
        static func unpair(pairId: String) -> Command {
            Command("unpair", arguments: [pairId])
        }

        /// Set a given pair as active.
        static func pairActivate(pairId: String) -> Command {
            Command("pair_activate", arguments: [pairId])
        }

        /// Erase a device's contents and settings.
        static func erase(_ erase: Erase) -> Command {
            Command("erase", arguments: erase.arguments)
        }

        /// Boot a device.
        static func boot(deviceId: String) -> Command {
            Command("boot", arguments: [deviceId])
        }

        /// Shutdown a device.
        static func shutdown(_ shutdown: ShutDown) -> Command {
            Command("shutdown", arguments: shutdown.arguments)
        }

        /// Rename a device.
        static func rename(deviceId: String, name: String) -> Command {
            Command("rename", arguments: [deviceId, name])
        }

        /// Print an environment variable from a running device.
        static func getEnvironmentVariable(deviceId: String, variable: String) -> Command {
            Command("getenv", arguments: [deviceId, variable])
        }

        /// Open a URL in a device.
        static func openURL(deviceId: String, url: String) -> Command {
            Command("openurl", arguments: [deviceId, url])
        }

        /// Add photos, live photos, videos, or contacts to the library of a device.
        static func addMedia(deviceId: String, mediaPaths: [String]) -> Command {
            Command("addmedia", arguments: [deviceId] + mediaPaths)
        }

        /// Install an app on a device.
        static func install(deviceId: String, path: String) -> Command {
            Command("install", arguments: [deviceId, path])
        }

        /// Uninstall an app from a device.
        static func uninstall(deviceId: String, appBundleId: String) -> Command {
            Command("uninstall", arguments: [deviceId, appBundleId])
        }

        /// Print the path of the installed app's container
        static func getAppContainer(deviceId: String, appBundleID: String, container: Container? = nil) -> Command {
            Command("get_app_container", arguments: [deviceId, appBundleID] + (container?.arguments ?? []))
        }

        /// Launch an application by identifier on a device.
        static func launch(deviceId: String, appBundleId: String, waitForDebugger: Bool = false, output: Launch.Output? = nil) -> Command {
            Command("launch", arguments: [deviceId, appBundleId] + (waitForDebugger ? ["-w"] : []) + (output?.arguments ?? []))
        }

        /// Terminate an application by identifier on a device.
        static func terminate(deviceId: String, appBundleId: String) -> Command {
            Command("terminate", arguments: [deviceId, appBundleId])
        }

        /// Spawn a process by executing a given executable on a device.
        static func spawn(deviceId: String, pathToExecutable: String, options: [Spawn.Option] = []) -> Command {
            Command("spawn", arguments: options.flatMap { $0.arguments } + [deviceId, pathToExecutable])
        }

        /// List available devices, device types, runtimes, or device pairs.
        static func list(filter: List.Filter? = nil, search: List.Search? = nil, flags: [List.Flag] = []) -> Command {
            var arguments: [String] = []

            if let filter = filter {
                arguments.append(contentsOf: filter.arguments)
            }

            if let search = search {
                arguments.append(contentsOf: search.arguments)
            }

            return Command("list", arguments: arguments + flags.flatMap { $0.arguments })
        }

        /// Show the installed applications.
        static func listApps(deviceId: String, flags: [List.Flag] = []) -> Command {
            Command("listapps", arguments: [deviceId] + flags.flatMap { $0.arguments })
        }

        /// Trigger iCloud sync on a device.
        static func icloudSync(deviceId: String) -> Command {
            Command("icloud_sync", arguments: [deviceId])
        }

        /// Sync the pasteboard content from one pasteboard to another.
        static func pbsync(source: Pasteboard.Device, destination: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbsync", arguments: source.arguments + destination.arguments + flags.flatMap { $0.arguments })
        }

        /// Copy standard input onto the device pasteboard.
        static func pbcopy(device: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbcopy", arguments: device.arguments + flags.flatMap { $0.arguments })
        }

        /// Print the contents of the device's pasteboard to standard output.
        static func pbpaste(device: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbpaste", arguments: device.arguments + flags.flatMap { $0.arguments })
        }

        /// Set up a device IO operation.
        static func io(deviceId: String, operation: IO.Operation) -> Command {
            Command("io", arguments: [deviceId] + operation.arguments)
        }

        /// Collect diagnostic information and logs.
        static func diagnose(flags: [Diagnose.Flag]) -> Command {
            Command("diagnose", arguments: flags.flatMap { $0.arguments })
        }

        /// enable or disable verbose logging for a device
        static func logverbose(deviceId: String?, isEnabled: Bool = false) -> Command {
            var arguments = [String]()

            if let deviceId = deviceId {
                arguments.append(deviceId)
            }

            return Command("logverbose", arguments: arguments + [(isEnabled ? "enabled" : "disabled")])
        }

        /// Set or clear status bar overrides
        static func statusBar(deviceId: String, operation: StatusBar.Operation) -> Command {
            Command("status_bar", arguments: [deviceId] + operation.arguments)
        }

        /// Get or Set UI options
        static func ui(deviceId: String, option: UI.Option) -> Command {
            Command("ui", arguments: [deviceId] + option.arguments)
        }

        /// Send a simulated push notification
        static func push(deviceId: String, appBundleId: String? = nil, json: Push.JSON) -> Command {
            var arguments: [String] = [deviceId]

            if let appBundleId = appBundleId {
                arguments.append(appBundleId)
            }

            return Command("push", arguments: arguments + json.arguments)
        }

        /// Grant, revoke, or reset privacy and permissi Manipulate a device's keychain
        static func privacy(deviceId: String, action: Privacy.Action, service: Privacy.Permission, appBundleId: String? = nil) -> Command {
            var arguments: [String] = [deviceId] + action.arguments + service.arguments

            if let appBundleId = appBundleId {
                arguments.append(appBundleId)
            }

            return Command("privacy", arguments: arguments)
        }

        /// Manipulate a device's keychain
        static func keychain(deviceId: String, action: Keychain.Action) -> Command {
            Command("keychain", arguments: [deviceId] + action.arguments)
        }
    }

    // swiftlint:disable nesting
    enum Delete {
        case devices([String])
        case unavailable
        case all

        var arguments: [String] {
            switch self {
            case .devices(let devices):
                return devices
            case .unavailable:
                return ["unavailable"]
            case .all:
                return ["all"]
            }
        }
    }

    enum Erase {
        case devices([String])
        case all

        var arguments: [String] {
            switch self {
            case .devices(let devices):
                return devices
            case .all:
                return ["all"]
            }
        }
    }

    enum ShutDown {
        case devices([String])
        case all

        var arguments: [String] {
            switch self {
            case .devices(let devices):
                return devices
            case .all:
                return ["all"]
            }
        }
    }

    enum Container {
        case app
        case data
        case groups
        case group(String)

        var arguments: [String] {
            switch self {
            case .app:
                return ["app"]
            case .data:
                return ["data"]
            case .groups:
                return ["groups"]
            case .group(let groupId):
                return [groupId]
            }
        }
    }

    struct Launch {
        enum Output {
            case console
            case consolePTY
            case std(outPath: String?, errPath: String?)

            var arguments: [String] {
                switch self {
                case .console:
                    return ["--console"]
                case .consolePTY:
                    return ["--consolePTY"]
                case .std(outPath: let out, errPath: let err):
                    var arguments = [String]()
                    if let out = out {
                        arguments.append("--stdout=\"\(out)\"")
                    }
                    if let err = err {
                        arguments.append("--stderr=\"\(err)\"")
                    }
                    return arguments
                }
            }
        }
    }

    enum Spawn {
        enum Option {
            case waitForDebugger
            case standalone
            case arch(String)

            var arguments: [String] {
                switch self {
                case .waitForDebugger:
                    return ["-w"]
                case .standalone:
                    return ["-s"]
                case .arch(let arch):
                    return ["--arch=\(arch)"]
                }
            }
        }
    }

    enum List {
        enum Filter: String {
            case devices
            case devicetypes
            case runtimes
            case pairs

            var arguments: [String] {
                return [rawValue]
            }
        }

        enum Search {
            case string(String)
            case available

            var arguments: [String] {
                switch self {
                case .string(let string):
                    return [string]
                case .available:
                    return ["available"]
                }
            }
        }

        enum Flag: String {
            case json = "-j"
            case verbose = "-v"

            var arguments: [String] {
                [self.rawValue]
            }
        }
    }

    enum Pasteboard {
        enum Device {
            case deviceId(String)
            case host

            var arguments: [String] {
                switch self {
                case .deviceId(let device):
                    return [device]
                case .host:
                    return ["host"]
                }
            }
        }

        enum Flag: String {
            case verbose = "-v"
            case promise = "-p"

            var arguments: [String] {
                [self.rawValue]
            }
        }
    }

    //swiftlint:disable type_name
    enum IO {
    //swiftlint:enable type_name
        enum Operation {
            case enumerate(poll: Bool = false)
            case poll
            case recordVideo(codec: Codec? = nil, display: Display? = nil, mask: Mask? = nil, force: Bool = false, url: String)
            case screenshot(type: ImageFormat? = nil, display: Display? = nil, mask: Mask? = nil, url: String)

            struct RecordVideo {
                enum Flags {
                    case codec(Codec)
                    case display(Display)
                    case mask(Mask)
                    case force

                    var arguments: [String] {
                        switch self {
                        case .codec(let codec):
                            return codec.arguments
                        case .display(let display):
                            return display.arguments
                        case .mask(let mask):
                            return mask.arguments
                        case .force:
                            return ["--force"]
                        }
                    }
                }
            }

            struct Screenshot {
                enum Flags {
                    case type(ImageFormat)
                    case display(Display)
                    case mask(Mask)

                    var arguments: [String] {
                        switch self {
                        case .type(let type):
                            return type.arguments
                        case .display(let display):
                            return display.arguments
                        case .mask(let mask):
                            return mask.arguments
                        }
                    }
                }
            }

            var arguments: [String] {
                switch self {
                case .enumerate(poll: let poll):
                    return ["enumerate"] + (poll ? ["--poll"] : [])
                case .poll:
                    return ["poll"]
                case .recordVideo(let codec, let display, let mask, let force, let url):
                    var arguments = [String]()

                    if let codec = codec {
                        arguments.append(contentsOf: codec.arguments)
                    }

                    if let display = display {
                        arguments.append(contentsOf: display.arguments)
                    }

                    if let mask = mask {
                        arguments.append(contentsOf: mask.arguments)
                    }

                    return ["recordVideo"] + arguments + (force ? ["--force"] : []) + [url]
                case .screenshot(let type, let display, let mask, let url):
                    var arguments = [String]()

                    if let type = type {
                        arguments.append(contentsOf: type.arguments)
                    }

                    if let display = display {
                        arguments.append(contentsOf: display.arguments)
                    }

                    if let mask = mask {
                        arguments.append(contentsOf: mask.arguments)
                    }

                    return ["screenshot"] + arguments + [url]
                }
            }
        }

        enum Codec: String {
            case h264
            case hevc

            var arguments: [String] {
                ["--codec=\(self.rawValue)"]
            }

            static let all = [Self.h264, .hevc]
        }

        enum Display: String {
            case `internal`
            case external

            var arguments: [String] {
                ["--display=\(self.rawValue)"]
            }

            static let all: [Self?] = [Self.internal, .external, nil]
        }

        enum Mask: String {
            case ignored
            case alpha
            case black

            var arguments: [String] {
                ["--mask=\(self.rawValue)"]
            }

            static let all: [Self?] = [Self.ignored, .alpha, .black, nil]
        }

        enum ImageFormat: String, CaseIterable {
            case png
            case tiff
            case bmp
            case jpeg

            var arguments: [String] {
                ["--type=\(self.rawValue)"]
            }
        }
    }

    enum Diagnose {
        enum Flag {
            case noShowInFinder
            case noTimeout
            case timeout(TimeInterval)
            case noArchive
            case allLogs
            case dataContainers
            case udid([String])

            var arguments: [String] {
                switch self {
                case .noShowInFinder:
                    return ["-b"]
                case .noTimeout:
                    return ["-X"]
                case .timeout(let timeout):
                    return ["--timeout=\(timeout)"]
                case .noArchive:
                    return ["--no-archive"]
                case .allLogs:
                    return ["--all-logs"]
                case .dataContainers:
                    return ["--data-containers"]
                case .udid(let udids):
                    return ["--udid="] + udids
                }
            }
        }
    }

    enum StatusBar {
        enum Operation {
            case list
            case clear
            case override([Override])

            var arguments: [String] {
                switch self {
                case .list:
                    return ["list"]
                case .clear:
                    return ["clear"]
                case .override(let overrides):
                    return ["override"] + overrides.flatMap { $0.arguments }
                }
            }

            enum Override {
                case time(String)
                case dataNetwork(DataNetwork)
                case wifiMode(WifiMode)
                case wifiBars(WifiBars)
                case cellularMode(CellularMode)
                case cellularBars(CellularBars)
                case operatorName(String)
                case batteryState(BatteryState)
                case batteryLevel(Int)

                var arguments: [String] {
                    switch self {
                    case .time(let time):
                        return ["--time", time]
                    case .dataNetwork(let network):
                        return ["--dataNetwork", network.rawValue]
                    case .wifiMode(let mode):
                        return ["--wifiMode", mode.rawValue]
                    case .wifiBars(let bars):
                        return ["--wifiBars", "\(bars.rawValue)"]
                    case .cellularMode(let mode):
                        return ["--cellularMode", mode.rawValue]
                    case .cellularBars(let bars):
                        return ["--cellularBars", "\(bars.rawValue)"]
                    case .operatorName(let name):
                        return ["--operatorName", name]
                    case .batteryState(let state):
                        return ["--batteryState", state.rawValue]
                    case .batteryLevel(let level):
                        return ["--batteryLevel", "\(level)"]
                    }
                }
            }
        }

        enum DataNetwork: String, CaseIterable {
            case wifi = "wifi"
            case threeG = "3g"
            case fourG = "4g"
            case lte = "lte"
            case lteA = "lte-a"
            case ltePlus = "lte+"
        }

        enum WifiMode: String, CaseIterable {
            case searching
            case failed
            case active
        }

        enum WifiBars: Int, CaseIterable {
            case zero
            case one
            case two
            case three
        }

        enum CellularMode: String, CaseIterable {
            case notSupported
            case searching
            case failed
            case active
        }

        enum CellularBars: Int, CaseIterable {
            case zero
            case one
            case two
            case three
            case four
        }

        enum BatteryState: String, CaseIterable {
            case charging
            case charged
            case discharging
        }
    }

    //swiftlint:disable type_name
    enum UI {
    //swiftlint:enable type_name
        enum Option {
            case appearance(Appearance)

            var arguments: [String] {
                switch self {
                case .appearance(let appearance):
                    return ["appearance", appearance.rawValue]
                }
            }
        }

        enum Appearance: String, CaseIterable {
            case light
            case dark
        }
    }

    enum Push {
        enum JSON {
            case path(String)
            case stdin

            var arguments: [String] {
                switch self {
                case .path(let path):
                    return [path]
                case .stdin:
                    return ["-"]
                }
            }
        }
    }

    enum Privacy {
        enum Action: String {
            case grant
            case revoke
            case reset

            var arguments: [String] {
                [self.rawValue]
            }
        }

        enum Permission: String, CaseIterable {
            case all
            case calendar
            case contactsLimited = "contacts-limited"
            case contacts
            case location
            case locationAlways = "location-always"
            case photosAdd
            case photos
            case mediaLibrary = "media-library"
            case microphone
            case motion
            case reminders
            case siri

            var arguments: [String] {
                [self.rawValue]
            }
        }
    }

    enum Keychain {
        enum Action {
            case addRootCert(path: String)
            case addCert(path: String)
            case reset

            var arguments: [String] {
                switch self {
                case .addRootCert(path: let path):
                    return ["add-root-cert", path]
                case .addCert(path: let path):
                    return ["add-cert", path]
                case .reset:
                    return ["reset"]
                }
            }
        }
    }

    // swiftlint:enable nesting
}
// swiftlint:enable file_length
