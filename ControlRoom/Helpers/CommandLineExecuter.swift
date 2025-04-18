//
//  CommandLineExecuter.swift
//  ControlRoom
//
//  Created by Mario Iannotta on 30/03/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine
import Foundation

/**
 FYI: Using Swift 5.3 it's possible to abstract also the error with something like this
 ```
 protocol CommandLineErrorRepresentable: Error {
     static var missingCommand: Self { get }
     static var missingOutput: Self { get }
     static func unknown(_ error: Error) -> Self
 }

 enum CommandLineCommandExecuterError: CommandLineErrorRepresentable
    case missingCommand
    case missingOutput
    case unknownError(Error)
 }

 protocol CommandLineCommandExecuter {
    ...
    associatedtype CommandLineError: CommandLineErrorRepresentable = CommandLineCommandExecuterError
    ...

    static func execute(_ arguments: [String], completion: @escaping (Result<Data, CommandLineError>) -> Void) {
        ....
    }
 }
 ```
 */
enum CommandLineError: Error {
    case missingCommand
    case missingOutput
    case unknown(Swift.Error)
}

protocol CommandLineCommand {
    var command: String? { get }
    var arguments: [String] { get }
    var environmentOverrides: [String: String]? { get }
}

protocol CommandLineCommandExecuter {
    associatedtype Command: CommandLineCommand
    static var launchPath: String { get }
}

extension CommandLineCommand {
    var command: String? { nil }
}

extension CommandLineCommandExecuter {

    private static func execute(_ command: Command, completion: @escaping (Result<Data, CommandLineError>) -> Void) {
        let commandToExecute: String = command.command ?? launchPath
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = Process.execute(commandToExecute, arguments: command.arguments, environmentOverrides: command.environmentOverrides) {
                completion(.success(data))
            } else {
                completion(.failure(.missingCommand))
            }
        }
    }

    static func executeAsync(_ command: Command) -> Process {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = command.arguments

        let pipe = Pipe()
        task.standardOutput = pipe

        try? task.run()
        return task
    }

    static func executeSubject(_ command: Command) -> PassthroughSubject<Data, CommandLineError> {
        let publisher = PassthroughSubject<Data, CommandLineError>()

        execute(command) { result in
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
    
    static func execute(_ command: Command, completion: ((Result<Data, CommandLineError>) -> Void)? = nil) {
        execute(command, completion: completion ?? { _ in })
    }

    static func executeJSON<T: Decodable>(_ command: Command) -> AnyPublisher<T, CommandLineError> {
        executeAndDecode(command, decoder: JSONDecoder())
    }

    static func executePropertyList<T: Decodable>(_ command: Command) -> AnyPublisher<T, CommandLineError> {
        executeAndDecode(command, decoder: PropertyListDecoder())
    }

    private static func executeAndDecode<Item, Decoder>(_ command: Command, decoder: Decoder) -> AnyPublisher<Item, CommandLineError> where Item: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {
        executeSubject(command)
            .decode(type: Item.self, decoder: decoder)
            .mapError { error -> CommandLineError in
                if error is DecodingError {
                    return .missingOutput
                } else if let command = error as? CommandLineError {
                    return command
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
