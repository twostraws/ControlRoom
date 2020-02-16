//
//  Preferences.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

class Preferences: ObservableObject {
    private var observationToken: NSObjectProtocol?

    @UserDefault("CRWantsFloatingWindow") var wantsFloatingWindow: Bool = false
    @UserDefault("CRSidebar_ShowOnlyActiveDevices") var shouldShowOnlyActiveDevices: Bool = false
    @UserDefault("CRSidebar_FilterText") var filterText: String = ""

    init() {
        observationToken = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                                                  object: UserDefaults.standard,
                                                                  queue: .main,
                                                                  using: { [weak self] _ in
                                                                    self?.objectWillChange.send()
        })
    }
}

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        UserDefaults.standard.register(defaults: [key: wrappedValue])
    }

    var wrappedValue: Value {
        get { (UserDefaults.standard.value(forKey: key) as? Value) ?? defaultValue }
        set { UserDefaults.standard.setValue(newValue, forKey: key) }
    }
}
