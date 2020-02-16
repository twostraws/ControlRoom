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

    private static func executeJSON<T: Decodable>(_ arguments: [String]) -> AnyPublisher<T, SimCtl.Error> {
        executeAndDecode(arguments, decoder: JSONDecoder())
    }

    private static func executePropertyList<T: Decodable>(_ arguments: [String]) -> AnyPublisher<T, SimCtl.Error> {
        executeAndDecode(arguments, decoder: PropertyListDecoder())
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
        executeJSON(["list", "devicetypes", "-j"])
    }

    static func listDevices() -> AnyPublisher<DeviceList, SimCtl.Error> {
        executeJSON(["list", "devices", "available", "-j"])
    }

    static func listRuntimes() -> AnyPublisher<RuntimeList, SimCtl.Error> {
        executeJSON(["list", "runtimes", "-j"])
    }

    static func listApplications(_ simulator: String) -> AnyPublisher<ApplicationsList, SimCtl.Error> {
        executePropertyList(["listapps", simulator, "-j"])
    }

    static func boot(_ simulator: String) {
        execute(["boot", simulator]) { _ in }
    }

    static func shutdown(_ simulator: String) {
        execute(["shutdown", simulator]) { _ in }
    }

    static func erase(_ simulator: String) {
        execute(["erase", simulator]) { _ in }
    }

    static func clone(_ simulator: String, name: String) {
        execute(["clone", simulator, name]) { _ in }
    }

    static func rename(_ simulator: String, name: String) {
        execute(["rename", simulator, name]) { _ in }
    }

    static func overrideStatusBarBattery(_ simulator: String, level: Int, state: String) {
        execute(["status_bar", simulator, "override", "--batteryLevel", "\(level)", "--batteryState", state]) { _ in }
    }

    static func overrideStatusBarNetwork(_ simulator: String, network: String, wifiMode: String, wifiBars: Int, cellMode: String, cellBars: Int, carrier: String) {
        execute(["status_bar", simulator, "override",
                 "--dataNetwork", network.lowercased(),
                 "--wifiMode", wifiMode.lowercased(),
                 "--wifiBars", "\(wifiBars)",
                 "--cellularMode", cellMode.lowercased(),
                 "--cellularBars", "\(cellBars)",
                 "--operatorName", carrier
        ]) { _ in }
    }

    static func overrideStatusBarTime(_ simulator: String, time: Date) {
        let timeString = ISO8601DateFormatter().string(from: time)
        execute(["status_bar", simulator, "override", "--time", timeString]) { _ in }
    }

    static func setAppearance(_ simulator: String, appearance: String) {
        execute(["ui", simulator, "appearance", appearance.lowercased()]) { _ in }
    }

    static func triggeriCloudSync(_ simulator: String) {
        execute(["icloud_sync", simulator]) { _ in }
    }

    static func copyPasteboardToMac(_ simulator: String) {
        execute(["pbsync", simulator, "host"]) { _ in }
    }

    static func copyPasteboardToSimulator(_ simulator: String) {
        execute(["pbsync", "host", simulator]) { _ in }
    }

    static func saveScreenshot(_ simulator: String, to file: String) {
        execute(["io", simulator, "screenshot", file]) { _ in }
    }

    static func delete(_ simulators: Set<String>) {
        execute(["delete"] + Array(simulators)) { _ in }
    }

    static func uninstall(_ simulator: String, appID: String) {
        execute(["uninstall", simulator, appID]) { _ in }
    }

    static func sendPushNotification(_ simulator: String, appID: String, jsonPayload: String) {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = "\(UUID().uuidString).json"
        let tempFile = tempDirectory.appendingPathComponent(fileName)
        do {
            try jsonPayload.write(to: tempFile, atomically: true, encoding: .utf8)
            execute(["push", simulator, appID, tempFile.path]) { _ in
                try? FileManager.default.removeItem(at: tempFile)
            }
        } catch {
            print("Cannot write json payload to \(tempFile.path)")
        }
    }

    static func openURL(_ simulator: String, URL: String) {
        execute(["openurl", simulator, URL]) { _ in }
    }

    static func grantPermission(_ simulator: String, appID: String, permission: String) {
        execute(["privacy", simulator, "grant", permission.lowercased(), appID]) { _ in }
    }

    static func revokePermission(_ simulator: String, appID: String, permission: String) {
        execute(["privacy", simulator, "revoke", permission.lowercased(), appID]) { _ in }
    }

    static func resetPermission(_ simulator: String, appID: String, permission: String) {
        execute(["privacy", simulator, "reset", permission.lowercased(), appID]) { _ in }
    }

    static func getAppContainer(_ simulator: String, appID: String, completion: @escaping (URL?) -> Void) {
        execute(["get_app_container", simulator, appID]) { result in
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
