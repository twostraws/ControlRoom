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
    enum SubCommand {
        /// Create a new device.
        case create(name: String, deviceTypeId: String, runtimeId: String? = nil)
        /// Clone an existing device.
        case clone(deviceId: String, name: String)
        /// Upgrade a device to a newer runtime.
        case upgrade(deviceId: String, runtimeId: String)
        /// Delete spcified devices, unavailable devices, or all devices.
        case delete(Delete)
        /// Create a new watch and phone pair.
        case pair(watch: String, phone: String)
        /// Unpair a watch and phone pair.
        case unpair(pairId: String)
        /// Set a given pair as active.
        case pairActivate(pairId: String)
        /// Erase a device's contents and settings.
        case erase(Erase)
        /// Boot a device.
        case boot(deviceId: String)
        /// Shutdown a device.
        case shutdown(ShutDown)
        /// Rename a device.
        case rename(deviceId: String, name: String)
        /// Print an environment variable from a running device.
        case getenv(deviceId: String, variable: String)
        /// Open a URL in a device.
        case openurl(deviceId: String, url: String)
        /// Add photos, live photos, videos, or contacts to the library of a device.
        case addmedia(deviceId: String, mediaPaths: [String])
        /// Install an app on a device.
        case install(deviceId: String, path: String)
        /// Uninstall an app from a device.
        case uninstall(deviceId: String, appBundleId: String)
        /// Print the path of the installed app's container
        case getAppContainer(deviceId: String, appBundleID: String, container: Container? = nil)
        /// Launch an application by identifier on a device.
        case launch(deviceId: String, appBundleId: String, waitForDebugger: Bool = false, output: Launch.Output? = nil)
        /// Terminate an application by identifier on a device.
        case terminate(deviceId: String, appBundleId: String)
        /// Spawn a process by executing a given executable on a device.
        case spawn(deviceId: String, pathToExecutable: String, options: [Spawn.Option] = [])
        /// List available devices, device types, runtimes, or device pairs.
        case list(filter: List.Filter? = nil, search: List.Search? = nil, flags: [List.Flag] = [])
        /// Show the installed applications.
        case listApps(deviceId: String, flags: [List.Flag] = [])
        /// Trigger iCloud sync on a device.
        case icloudSync(deviceId: String)
        /// Sync the pasteboard content from one pasteboard to another.
        case pbsync(source: Pasteboard.Device, destination: Pasteboard.Device, flags: [Pasteboard.Flag] = [])
        /// Copy standard input onto the device pasteboard.
        case pbcopy(device: Pasteboard.Device, flags: [Pasteboard.Flag] = [])
        /// Print the contents of the device's pasteboard to standard output.
        case pbpaste(device: Pasteboard.Device, flags: [Pasteboard.Flag] = [])
        /// Set up a device IO operation.
        case io(deviceId: String, operation: IO.Operation)
        /// Collect diagnostic information and logs.
        case diagnose(flags: [Diagnose.Flag])
        /// enable or disable verbose logging for a device
        case logverbose(deviceId: String?, isEnabled: Bool = false)
        /// Set or clear status bar overrides
        case statusBar(deviceId: String, operation: StatusBar.Operation)
        /// Get or Set UI options
        case ui(deviceId: String, option: UI.Option)
        /// Send a simulated push notification
        case push(deviceId: String, appBundleId: String? = nil, json: Push.JSON)
        /// Grant, revoke, or reset privacy and permissi Manipulate a device's keychain
        case privacy(deviceId: String, action: Privacy.Action, service: Privacy.Permission, appBundleId: String? = nil)
        /// Manipulate a device's keychain
        case keychain(deviceId: String, action: Keychain.Action)

        var arguments: [String] {
            switch self {
            case .create(name: let name, deviceTypeId: let deviceTypeId, runtimeId: let runtimeId):
                var arguments = ["create", name, deviceTypeId]
                if let runtimeId = runtimeId {
                    arguments.append(runtimeId)
                }
                return arguments
            case .clone(deviceId: let deviceId, name: let name):
                return ["clone", deviceId, name]
            case .upgrade(deviceId: let deviceId, runtimeId: let runtimeId):
                return ["upgrade", deviceId, runtimeId]
            case .delete(let delete):
                return ["delete"] + delete.arguments
            case .pair(watch: let watch, phone: let phone):
                return ["pair", watch, phone]
            case .unpair(pairId: let pairId):
                return ["unpair", pairId]
            case .pairActivate(pairId: let pairId):
                return ["pair_activate", pairId]
            case .erase(let erase):
                return ["erase"] + erase.arguments
            case .boot(deviceId: let deviceId):
                return ["boot", deviceId]
            case .shutdown(let shutdown):
                return ["shutdown"] + shutdown.arguments
            case .rename(deviceId: let deviceId, name: let name):
                return ["rename", deviceId, name]
            case .getenv(deviceId: let deviceId, variable: let variable):
                return ["getenv", deviceId, variable]
            case .openurl(deviceId: let deviceId, url: let url):
                return ["openurl", deviceId, url]
            case .addmedia(deviceId: let deviceId, mediaPaths: let mediaPaths):
                return ["addmedia", deviceId] + mediaPaths
            case .install(deviceId: let deviceId, path: let path):
                return ["install", deviceId, path]
            case .uninstall(deviceId: let deviceId, appBundleId: let appBundleId):
                return ["uninstall", deviceId, appBundleId]
            case .getAppContainer(deviceId: let deviceId, appBundleID: let appBundleID, container: let container):
                return ["get_app_container", deviceId, appBundleID] + (container?.arguments ?? [])
            case .launch(deviceId: let deviceId, appBundleId: let appBundleId, waitForDebugger: let waitForDebugger, output: let output):
                return ["launch", deviceId, appBundleId] + (waitForDebugger ? ["-w"] : []) + (output?.arguments ?? [])
            case .terminate(deviceId: let deviceId, appBundleId: let appBundleId):
                return ["terminate", deviceId, appBundleId]
            case .spawn(deviceId: let deviceId, pathToExecutable: let pathToExecutable, options: let options):
                return ["spawn"] + options.flatMap { $0.arguments } + [deviceId, pathToExecutable]
            case .list(filter: let filter, search: let search, flags: let flags):
                var arguments: [String] = ["list"]
                if let filter = filter {
                    arguments.append(contentsOf: filter.arguments)
                }
                if let search = search {
                    arguments.append(contentsOf: search.arguments)
                }
                return arguments + flags.flatMap { $0.arguments }
            case .listApps(deviceId: let devicedId, flags: let flags):
                return ["listapps", devicedId] + flags.flatMap { $0.arguments }
            case .icloudSync(deviceId: let deviceId):
                return ["icloud_sync", deviceId]
            case .pbsync(source: let source, destination: let destination, flags: let flags):
                return ["pbsync"] + source.arguments + destination.arguments + flags.flatMap { $0.arguments }
            case .pbcopy(device: let device, flags: let flags):
                return ["pbcopy"] + device.arguments + flags.flatMap { $0.arguments }
            case .pbpaste(device: let device, flags: let flags):
                return ["pbpaste"] + device.arguments + flags.flatMap { $0.arguments }
            case .io(deviceId: let deviceId, operation: let operation):
                return ["io", deviceId] + operation.arguments
            case .diagnose(flags: let flags):
                return ["diagnose"] + flags.flatMap { $0.arguments }
            case .logverbose(deviceId: let deviceId, isEnabled: let isEnabled):
                var arguments: [String] = ["logverbose"]
                if let deviceId = deviceId {
                    arguments.append(deviceId)
                }
                return arguments + [(isEnabled ? "enabled" : "disabled")]
            case .statusBar(deviceId: let deviceId, operation: let operation):
                return ["status_bar", deviceId] + operation.arguments
            case .ui(deviceId: let deviceId, option: let option):
                return ["ui", deviceId] + option.arguments
            case .push(deviceId: let deviceId, appBundleId: let appBundleId, json: let json):
                var arguments: [String] = ["push", deviceId]
                if let appBundleId = appBundleId {
                    arguments.append(appBundleId)
                }
                return arguments + json.arguments
            case .privacy(deviceId: let deviceId, action: let action, service: let service, appBundleId: let appBundleId):
                var arguments: [String] = ["privacy", deviceId] + action.arguments + service.arguments
                if let appBundleId = appBundleId {
                    arguments.append(appBundleId)
                }
                return arguments
            case .keychain(deviceId: let deviceId, action: let action):
                return ["keychain", deviceId] + action.arguments
            }
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
                    var arguments: [String] = []
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
                    var arguments: [String] = []
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
                    var arguments: [String] = []
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
                return ["--codec=\(self.rawValue)"]
            }
        }

        enum Display: String {
            case `internal`
            case external

            var arguments: [String] {
                return ["--display=\(self.rawValue)"]
            }
        }

        enum Mask: String {
            case ignored
            case alpha
            case black

            var arguments: [String] {
                return ["--mask=\(self.rawValue)"]
            }
        }

        enum ImageFormat: String {
            case png
            case tiff
            case bmp
            case gif
            case jpeg

            var arguments: [String] {
                return ["--type=\(self.rawValue)"]
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
                return [self.rawValue]
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
                return [self.rawValue]
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
