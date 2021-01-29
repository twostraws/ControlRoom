//
//  Preferences.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine
import KeyboardShortcuts
import SwiftUI

class Preferences: ObservableObject {
    /// For parts of the app that want to observe a particular value directly,
    /// they need a way to be notified AFTER the value has changed.
    let objectDidChange = PassthroughSubject<Void, Never>()

    let userDefaults: UserDefaults

    @UserDefault("CRWantsMenuBarIcon") var wantsMenuBarIcon = true
    @UserDefault("CRWantsFloatingWindow") var wantsFloatingWindow = false
    @UserDefault("CRLastSimulatorUDID") var lastSimulatorUDID = "booted"

    @UserDefault("CRSidebar_ShowDefaultSimulator") var showDefaultSimulator = true
    @UserDefault("CRSidebar_ShowBootedDevicesFirst") var showBootedDevicesFirst = false
    @UserDefault("CRSidebar_ShowOnlyActiveDevices") var shouldShowOnlyActiveDevices = false
    @UserDefault("CRSidebar_FilterText") var filterText = ""

    @UserDefault("CRApps_LastOpenURL") var lastOpenURL = ""
    @UserDefault("CRApps_LastBundleID") var lastBundleID = ""
    @UserDefault("CRApps_ShowSystemApps") var shouldShowSystemApps = true
    @UserDefault("CRApps_PushPayload") var pushPayload = """
    {
        "aps": {
            "alert": {
                "body": "Hello, World!",
                "title": "From Control Room"
            }
        }
    }
    """

    @UserDefault("CRNetwork_CarrierName") var carrierName = "Carrier"
    @UserDefault("CRMedia_VideoFormat") var videoFormat = 0

    init(defaults: UserDefaults = .standard) {
        userDefaults = defaults
    }
}

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    var wrappedValue: Value {
        get { fatalError("called wrappedValue getter") }
        // swiftlint:disable unused_setter_value
        set { fatalError("called wrappedValue setter") }
        // swiftlint:enable unused_setter_value
    }

    /// This uses a prototype Property Wrapper feature to get access to the "enclosing self".
    /// In other words, this allows us to get access to "self": the object that holds the property wrapper.
    /// By using this, we can directly access the Preferences's "objectWillChange" publisher, as well
    /// as its stored UserDefaults instance.
    static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let wrapper = instance[keyPath: storageKeyPath]

            guard let anyValue = instance.userDefaults.value(forKey: wrapper.key) else {
                return wrapper.defaultValue
            }

            guard let value = anyValue as? Value else {
                return wrapper.defaultValue
            }

            return value
        }

        set {
            instance.objectWillChange.send()

            let wrapper = instance[keyPath: storageKeyPath]
            instance.userDefaults.set(newValue, forKey: wrapper.key)
            instance.objectDidChange.send()
        }
    }
}
