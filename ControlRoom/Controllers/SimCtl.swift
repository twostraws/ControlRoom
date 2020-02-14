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
            if let data = Process.execute("/usr/bin/xcrun", arguments: ["simctl"] + arguments) {
                completion(.success(data))
            } else {
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

    static func watchDeviceList() -> AnyPublisher<DeviceList, Command.CommandError> {
        if CoreSimulator.canRegisterForSimulatorNotifications {
            return CoreSimulatorPublisher()
                .mapError({ _ in return Command.CommandError.missingCommand })
                .flatMap({ _ in return SimCtl.listDevices() })
                .prepend(SimCtl.listDevices())
                .removeDuplicates()
                .eraseToAnyPublisher()
        } else {
            return Timer.publish(every: 5, on: .main, in: .common)
                .autoconnect()
                .setFailureType(to: Command.CommandError.self)
                .flatMap({ _ in return SimCtl.listDevices() })
                .prepend(SimCtl.listDevices())
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
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
