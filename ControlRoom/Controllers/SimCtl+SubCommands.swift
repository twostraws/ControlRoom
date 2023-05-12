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
        static var group: DeviceGroup = .default
        let arguments: [String]
        let environmentOverrides: [String: String]?

        private init(_ subcommand: String, arguments: [String], environmentOverrides: [String: String]? = nil) {
            var commands = ["simctl"]
            commands.append(contentsOf: Self.group.commands)
            commands.append(subcommand)
            commands.append(contentsOf: arguments)
            self.arguments = commands
            self.environmentOverrides = environmentOverrides
        }

        /// Create a new device.
        static func create(name: String, deviceTypeId: String, runtimeId: String? = nil) -> Command {
            Command("create", arguments: [name, deviceTypeId])
        }
        /// Set logging.
        static func setLogging(deviceTypeId: String, enableLogging: Bool) -> Command {
            Command("logverbose", arguments: [deviceTypeId, String(describing: enableLogging)])
        }
        /// Get logs.
        static func getLogs(deviceTypeId: String) -> Command {
            Command("diagnose", arguments: [])
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
        static func boot(simulator: Simulator) -> Command {
            if let buildVersion = simulator.runtime?.buildversion, buildVersion.compare("16.0", options: .numeric) == .orderedDescending {
                // Workaround to make status_bar overrides work for simulators > 16.1.
                // See https://federated.saagarjha.com/notice/AUwNsSsOOCWFc8qCvY.
                return Command("boot", arguments: [simulator.udid], environmentOverrides: ["SIMCTL_CHILD_SIMULATOR_RUNTIME_VERSION": "16.0"])
            } else {
                return Command("boot", arguments: [simulator.udid])
            }
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

        static func addRootCert(deviceId: String, filePath: String) -> Command {
            Command("keychain", arguments: [deviceId, filePath])
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
            Command("spawn", arguments: options.flatMap(\.arguments) + [deviceId, pathToExecutable])
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

            return Command("list", arguments: arguments + flags.flatMap(\.arguments))
        }

        /// Show the installed applications.
        static func listApps(deviceId: String, flags: [List.Flag] = []) -> Command {
            Command("listapps", arguments: [deviceId] + flags.flatMap(\.arguments))
        }

        /// Trigger iCloud sync on a device.
        static func icloudSync(deviceId: String) -> Command {
            Command("icloud_sync", arguments: [deviceId])
        }

        /// Sync the pasteboard content from one pasteboard to another.
        static func pbsync(source: Pasteboard.Device, destination: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbsync", arguments: source.arguments + destination.arguments + flags.flatMap(\.arguments))
        }

        /// Copy standard input onto the device pasteboard.
        static func pbcopy(device: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbcopy", arguments: device.arguments + flags.flatMap(\.arguments))
        }

        /// Print the contents of the device's pasteboard to standard output.
        static func pbpaste(device: Pasteboard.Device, flags: [Pasteboard.Flag] = []) -> Command {
            Command("pbpaste", arguments: device.arguments + flags.flatMap(\.arguments))
        }

        /// Set up a device IO operation.
        static func io(deviceId: String, operation: IO.Operation) -> Command {
            Command("io", arguments: [deviceId] + operation.arguments)
        }

        /// Collect diagnostic information and logs.
        static func diagnose(flags: [Diagnose.Flag]) -> Command {
            Command("diagnose", arguments: flags.flatMap(\.arguments))
        }

        /// Set the user's current locaiton
        static func location(deviceId: String, latitude: Double, longitude: Double) -> Command {
            Command("location", arguments: [deviceId, "set", "\(latitude),\(longitude)"])
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
                [rawValue]
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
                [rawValue]
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
                [rawValue]
            }
        }
    }

    // swiftlint:disable type_name
    enum IO {
    // swiftlint:enable type_name
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
                ["--codec=\(rawValue)"]
            }

            static let all = [Self.h264, .hevc]
        }

        enum Display: String, CaseIterable {
            case `internal`
            case external

            var arguments: [String] {
                ["--display=\(rawValue)"]
            }
        }

        enum Mask: String, CaseIterable {
            case ignored
            case alpha
            case black

            var arguments: [String] {
                ["--mask=\(rawValue)"]
            }
        }

        enum ImageFormat: String, CaseIterable {
            case png
            case jpeg
            case tiff
            case bmp

            var arguments: [String] {
                ["--type=\(rawValue)"]
            }
        }

        enum VideoFormat: String {
            case h264, h264Compressed, divider, smallGif, mediumGif, largeGif, fullGif

            static var all: [VideoFormat] {
                var options: [VideoFormat] = [.h264, .divider, .smallGif, .mediumGif, .largeGif, .fullGif]

                if FFMPEGConverter.available {
                    options.insert(.h264Compressed, at: 1)
                }

                return options
            }

            var name: String {
                switch self {
                case .h264:
                    return "H.264"
                case .h264Compressed:
                    return "H.264 (Compressed)"
                case .divider:
                    return ""
                case .smallGif:
                    return "GIF (Small)"
                case .mediumGif:
                    return "GIF (Medium)"
                case .largeGif:
                    return "GIF (Large)"
                case .fullGif:
                    return "GIF (Full)"
                }
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
                    return ["override"] + overrides.flatMap(\.arguments)
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
                        return ["--wifiBars", "\(Int(bars.rawValue))"]
                    case .cellularMode(let mode):
                        return ["--cellularMode", mode.rawValue]
                    case .cellularBars(let bars):
                        return ["--cellularBars", "\(Int(bars.rawValue))"]
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
            case fiveG = "5g"
            case fiveGPlus = "5g+"
            case fiveGUWB = "5g-uwb"
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

            var symbolVariable: Double {
                Double(self.rawValue) / Double(Self.allCases.count)
            }
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

            var symbolVariable: Double {
                Double(self.rawValue) / Double(Self.allCases.count)
            }
        }

        enum BatteryState: String, CaseIterable {
            case charging
            case charged
            case discharging

            var displayName: String {
                rawValue.capitalized
            }
        }
    }

    // swiftlint:disable type_name
    public enum UI {
    // swiftlint:enable type_name
        enum Option {
            case appearance(Appearance)
            case contentSize(ContentSizes)

            var arguments: [String] {
                switch self {
                case .appearance(let appearance):
                    return ["appearance", appearance.rawValue]
                case .contentSize(let size):
                    switch size {
                    case .extraSmall:
                        return ["content_size", "extra-small"]
                    case .small:
                        return ["content_size", "small"]
                    case .medium:
                        return ["content_size", "medium"]
                    case .large:
                        return ["content_size", "large"]
                    case .extraLarge:
                        return ["content_size", "extra-large"]
                    case .extraExtraLarge:
                        return ["content_size", "extra-extra-large"]
                    case .extraExtraExtraLarge:
                        return ["content_size", "extra-extra-extra-large"]
                    case .accessibilityMedium:
                        return ["content_size", "accessibility-medium"]
                    case .accessibilityLarge:
                        return ["content_size", "accessibility-large"]
                    case .accessibilityExtraLarge:
                        return ["content_size", "accessibility-extra-large"]
                    case .accessibilityExtraExtraLarge:
                        return ["content_size", "accessibility-extra-extra-large"]
                    case .accessibilityExtraExtraExtraLarge:
                        return ["content_size", "accessibility-extra-extra-extra-large"]
                    }
                }
            }
        }

        enum Appearance: String, CaseIterable {
            case light
            case dark
        }
        enum ContentSizes: String, CaseIterable {
            case extraSmall = "Extra Small"
            case small = "Small"
            case medium = "Regular"
            case large = "Large"
            case extraLarge = "Extra Large"
            case extraExtraLarge = "Extra Extra Large"
            case extraExtraExtraLarge = "Extra Extra Extra Large"
            case accessibilityMedium = "Accessibility Medium"
            case accessibilityLarge = "Accessibility Large"
            case accessibilityExtraLarge = "Accessibility Extra Large"
            case accessibilityExtraExtraLarge = "Accessibility Extra Extra Large"
            case accessibilityExtraExtraExtraLarge = "Accessibility Extra Extra Extra Large"
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
                [rawValue]
            }
        }

        enum Permission: String, CaseIterable {
            case all
            case calendar
            case camera
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
                [rawValue]
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
