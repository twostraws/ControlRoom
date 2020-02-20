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
enum SimCtl {

    /// Errors we might get from running simctl
    enum Error: Swift.Error {
        case missingCommand
        case missingOutput
        case unknown(Swift.Error)
    }

    private static func execute(_ arguments: [String], completion: @escaping (Result<Data, SimCtl.Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = Process.execute("/usr/bin/xcrun", arguments: ["simctl"] + arguments) {
                completion(.success(data))
            } else {
                completion(.failure(.missingCommand))
            }
        }
    }

    private static func execute(_ arguments: [String]) -> PassthroughSubject<Data, SimCtl.Error> {
        let publisher = PassthroughSubject<Data, SimCtl.Error>()

        execute(arguments) { result in
            switch result {
            case .success(let data):
                publisher.send(data)
                publisher.send(completion: .finished)
            case .failure(let error):
                publisher.send(completion: .failure(error))
            }
        }

        return publisher
    }

    private static func execute(_ command: Command, completion: ((Result<Data, SimCtl.Error>) -> Void)? = nil) {
        execute(command.arguments, completion: completion ?? { _ in })
    }

    private static func executeJSON<T: Decodable>(_ command: Command) -> AnyPublisher<T, SimCtl.Error> {
        executeAndDecode(command.arguments, decoder: JSONDecoder())
    }

    private static func executePropertyList<T: Decodable>(_ command: Command) -> AnyPublisher<T, SimCtl.Error> {
        executeAndDecode(command.arguments, decoder: PropertyListDecoder())
    }

    private static func executeAndDecode<Item: Decodable, Decoder: TopLevelDecoder>(_ arguments: [String],
                                                                                    decoder: Decoder) -> AnyPublisher<Item, SimCtl.Error> where Decoder.Input == Data {
        execute(arguments)
            .decode(type: Item.self, decoder: decoder)
            .mapError({ error -> SimCtl.Error in
                if error is DecodingError {
                    return .missingOutput
                } else if let command = error as? SimCtl.Error {
                    return command
                } else {
                    return .unknown(error)
                }
            })
            .eraseToAnyPublisher()
    }

    static func watchDeviceList() -> AnyPublisher<DeviceList, SimCtl.Error> {
        if CoreSimulator.canRegisterForSimulatorNotifications {
            return CoreSimulatorPublisher()
                .mapError({ _ in return SimCtl.Error.missingCommand })
                .flatMap({ _ in return SimCtl.listDevices() })
                .prepend(SimCtl.listDevices())
                .removeDuplicates()
                .eraseToAnyPublisher()
        } else {
            return Timer.publish(every: 5, on: .main, in: .common)
                .autoconnect()
                .setFailureType(to: SimCtl.Error.self)
                .flatMap({ _ in return SimCtl.listDevices() })
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

    static func erase(_ simulator: String) {
        execute(.erase(.devices([simulator])))
    }

    static func clone(_ simulator: String, name: String) {
        execute(.clone(deviceId: simulator, name: name))
    }

    static func rename(_ simulator: String, name: String) {
        execute(.rename(deviceId: simulator, name: name))
    }

    static func overrideStatusBarBattery(_ simulator: String, level: Int, state: StatusBar.BatteryState) {
        execute(.statusBar(deviceId: simulator, operation: .override([.batteryLevel(level), .batteryState(state)])))
    }

    static func overrideStatusBarNetwork(_ simulator: String,
                                         network: StatusBar.DataNetwork,
                                         wifiMode: StatusBar.WifiMode,
                                         wifiBars: StatusBar.WifiBars,
                                         cellMode: StatusBar.CellularMode,
                                         cellBars: StatusBar.CellularBars,
                                         carrier: String) {
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

    static func saveScreenshot(_ simulator: String, to file: String) {
        execute(.io(deviceId: simulator, operation: .screenshot(url: file)))
    }

    static func delete(_ simulators: Set<String>) {
        execute(.delete(.devices(Array(simulators))))
    }

    static func uninstall(_ simulator: String, appID: String) {
        execute(.uninstall(deviceId: simulator, appBundleId: appID))
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
