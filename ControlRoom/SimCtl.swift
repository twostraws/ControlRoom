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
    private static func execute(_ arguments: [String], completion: @escaping (Result<Data, Command.CommandError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/xcrun"
            task.arguments = ["simctl"] + arguments

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                completion(.success(data))
            } catch {
                completion(.failure(.missingCommand))
            }
        }
    }

    private static func execute(_ arguments: [String]) -> PassthroughSubject<Data, Command.CommandError> {
        let publisher = PassthroughSubject<Data, Command.CommandError>()

        execute(arguments, completion: { result in
            switch result {
            case .success(let data):
                publisher.send(data)
                publisher.send(completion: .finished)
            case .failure(let error):
                publisher.send(completion: .failure(error))
            }
        })

        return publisher
    }

    private static func executeJSON<T: Decodable>(_ arguments: [String]) -> AnyPublisher<T, Command.CommandError> {
        execute(arguments).decode(type: T.self, decoder: JSONDecoder()).mapError({ error -> Command.CommandError in
            if error is DecodingError {
                return .missingOutput
            } else if let command = error as? Command.CommandError {
                return command
            } else {
                return .unknown(error)
            }
        }).eraseToAnyPublisher()
    }

    static func pollDeviceList(interval: TimeInterval = 5) -> AnyPublisher<DeviceList, Command.CommandError> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: Command.CommandError.self)
            .flatMap({ _ in return SimCtl.listDevices() })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    static func listDeviceTypes() -> AnyPublisher<DeviceTypeList, Command.CommandError> {
        executeJSON(["list", "devicetypes", "-j"])
    }

    static func listDevices() -> AnyPublisher<DeviceList, Command.CommandError> {
        executeJSON(["list", "devices", "available", "-j"])
    }

    static func listRuntimes() -> AnyPublisher<RuntimeList, Command.CommandError> {
        executeJSON(["list", "runtimes", "-j"])
    }
}
