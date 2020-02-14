//
//  CoreSimulatorPublisher.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/14/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine

enum CoreSimulatorError: Error {
    case missingFramework
}

// Thanks to @avanderlee for this great overview: https://www.avanderlee.com/swift/custom-combine-publisher/

/// A custom subscription to monitor for notifications from CoreSimulator.
final class CoreSimulatorSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == Void, SubscriberType.Failure == CoreSimulatorError {
    private var token: UInt?

    init(subscriber: SubscriberType) {
        let registrationToken = CoreSimulator.register {
            _ = subscriber.receive()
        }

        if registrationToken == NSNotFound {
            token = nil
            subscriber.receive(completion: .failure(CoreSimulatorError.missingFramework))
        } else {
            token = registrationToken
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        if let registrationToken = token {
            CoreSimulator.unregister(fromSimulatorNotifications: registrationToken)
        }
    }
}

struct CoreSimulatorPublisher: Publisher {
    typealias Output = Void
    typealias Failure = CoreSimulatorError

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == CoreSimulatorPublisher.Output, S.Failure == CoreSimulatorPublisher.Failure {
        let subscription = CoreSimulatorSubscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
