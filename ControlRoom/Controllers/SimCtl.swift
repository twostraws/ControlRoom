//
//  SimCtl.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/13/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine
import Foundation

/// A container for all the functionality for talking to simctl.
enum SimCtl: CommandLineCommandExecuter {
    typealias Error = CommandLineError

    static let launchPath = "/usr/bin/xcrun"

    static func watchDeviceList() -> AnyPublisher<DeviceList, SimCtl.Error> {
        if CoreSimulator.canRegisterForSimulatorNotifications {
            return CoreSimulatorPublisher()
                .mapError { _ in return SimCtl.Error.missingCommand }
                .flatMap { _ in return SimCtl.listDevices() }
                .prepend(SimCtl.listDevices())
                .removeDuplicates()
                .eraseToAnyPublisher()
        } else {
            return Timer.publish(every: 5, on: .main, in: .common)
                .autoconnect()
                .setFailureType(to: SimCtl.Error.self)
                .flatMap { _ in return SimCtl.listDevices() }
                .prepend(SimCtl.listDevices())
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
    }

    static func listDeviceTypes() -> AnyPublisher<DeviceTypeList, SimCtl.Error> {
        executeJSON(.list(filter: .devicetypes, flags: [.json]))
    }

    static func listDevices() -> AnyPublisher<DeviceList, SimCtl.Error> {
        executeJSON(.list(filter: .devices, search: .available, flags: [.json]))
    }

    static func listRuntimes() -> AnyPublisher<RuntimeList, SimCtl.Error> {
        executeJSON(.list(filter: .runtimes, flags: [.json]))
    }

    static func listApplications(_ simulator: String) -> AnyPublisher<ApplicationsList, SimCtl.Error> {
        executePropertyList(.listApps(deviceId: simulator, flags: [.json]))
    }

    static func boot(_ simulator: String) {
        execute(.boot(deviceId: simulator))
    }

    static func shutdown(_ simulator: String) {
        execute(.shutdown(.devices([simulator])))
    }

    static func reboot(_ simulator: String) {
        execute(.shutdown(.devices([simulator]))) { _ in
            execute(.boot(deviceId: simulator))
        }
    }

    static func erase(_ simulator: String) {
        execute(.erase(.devices([simulator])))
    }

    static func clone(_ simulator: String, name: String) {
        execute(.clone(deviceId: simulator, name: name))
    }

    static func create(name: String, deviceType: DeviceType, runtime: Runtime) {
        execute(.create(name: name, deviceTypeId: deviceType.identifier, runtimeId: runtime.identifier)) { _ in }
    }

    static func rename(_ simulator: String, name: String) {
        execute(.rename(deviceId: simulator, name: name))
    }

    static func overrideStatusBarBattery(_ simulator: String, level: Int, state: StatusBar.BatteryState) {
        execute(.statusBar(deviceId: simulator, operation: .override([.batteryLevel(level), .batteryState(state)])))
    }

    // swiftlint:disable:next function_parameter_count
    static func overrideStatusBarNetwork(
        _ simulator: String,
        network: StatusBar.DataNetwork,
        wifiMode: StatusBar.WifiMode,
        wifiBars: StatusBar.WifiBars,
        cellMode: StatusBar.CellularMode,
        cellBars: StatusBar.CellularBars,
        carrier: String
    ) {
        execute(.statusBar(deviceId: simulator, operation: .override([
            .dataNetwork(network),
            .wifiMode(wifiMode),
            .wifiBars(wifiBars),
            .cellularMode(cellMode),
            .cellularBars(cellBars),
            .operatorName(carrier)
        ])))
    }

    static func overrideStatusBarTime(_ simulator: String, time: Date) {
        let timeString = ISO8601DateFormatter().string(from: time)
        execute(.statusBar(deviceId: simulator, operation: .override([.time(timeString)])))
    }

    static func setAppearance(_ simulator: String, appearance: UI.Appearance) {
        execute(.ui(deviceId: simulator, option: .appearance(appearance)))
    }

    static func triggeriCloudSync(_ simulator: String) {
        execute(.icloudSync(deviceId: simulator))
    }

    static func copyPasteboardToMac(_ simulator: String) {
        execute(.pbsync(source: .deviceId(simulator), destination: .host))
    }

    static func copyPasteboardToSimulator(_ simulator: String) {
        execute(.pbsync(source: .host, destination: .deviceId(simulator)))
    }

    static func saveScreenshot(_ simulator: String, to file: String, type: IO.ImageFormat? = nil, display: IO.Display? = nil, with mask: IO.Mask? = nil) {
        execute(.io(deviceId: simulator, operation: .screenshot(type: type, display: display, mask: mask, url: file)))
    }

    static func startVideo(_ simulator: String, to file: String, type: IO.Codec? = nil, display: IO.Display? = nil, with mask: IO.Mask? = nil) -> Process {
        executeAsync(.io(deviceId: simulator, operation: .recordVideo(codec: type, display: display, mask: mask, force: true, url: file)))
    }

    static func delete(_ simulators: Set<String>) {
        execute(.delete(.devices(Array(simulators))))
    }

    static func uninstall(_ simulator: String, appID: String) {
        execute(.uninstall(deviceId: simulator, appBundleId: appID))
    }

    static func launch(_ simulator: String, appID: String) {
        execute(.launch(deviceId: simulator, appBundleId: appID))
    }

    static func terminate(_ simulator: String, appID: String) {
        execute(.terminate(deviceId: simulator, appBundleId: appID))
    }

    static func restart(_ simulator: String, appID: String) {
        terminate(simulator, appID: appID)

        // Wait a fraction of a section to ensure the system has terminated
        // the app before we relaunch it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            launch(simulator, appID: appID)
        }
    }

    static func sendPushNotification(_ simulator: String, appID: String, jsonPayload: String) {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = "\(UUID().uuidString).json"
        let tempFile = tempDirectory.appendingPathComponent(fileName)
        do {
            try jsonPayload.write(to: tempFile, atomically: true, encoding: .utf8)
            execute(.push(deviceId: simulator, appBundleId: appID, json: .path(tempFile.path))) { _ in
                try? FileManager.default.removeItem(at: tempFile)
            }
        } catch {
            print("Cannot write json payload to \(tempFile.path)")
        }
    }

    static func openURL(_ simulator: String, URL: String) {
        execute(.openURL(deviceId: simulator, url: URL))
    }

    static func grantPermission(_ simulator: String, appID: String, permission: Privacy.Permission) {
        execute(.privacy(deviceId: simulator, action: .grant, service: permission, appBundleId: appID))
    }

    static func revokePermission(_ simulator: String, appID: String, permission: Privacy.Permission) {
        execute(.privacy(deviceId: simulator, action: .revoke, service: permission, appBundleId: appID))
    }

    static func resetPermission(_ simulator: String, appID: String, permission: Privacy.Permission) {
        execute(.privacy(deviceId: simulator, action: .reset, service: permission, appBundleId: appID))
    }

    static func getAppContainer(_ simulator: String, appID: String, completion: @escaping (URL?) -> Void) {
        execute(.getAppContainer(deviceId: simulator, appBundleID: appID)) { result in
            let url: URL?

            switch result {
            case .success(let data):
                if let path = String(data: data, encoding: .utf8) {
                    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                    url = URL(fileURLWithPath: trimmed)
                } else {
                    url = nil
                }
            case .failure:
                url = nil
            }

            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
}
