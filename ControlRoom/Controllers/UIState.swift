//
//  UIState.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine

class UIState: ObservableObject {
    static let shared = UIState()

    private init() { }

    @Published var showPreferences = false
}
