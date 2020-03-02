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

    enum Sheet: Int, Identifiable {
        case preferences
        case createSimulator
        case notificationEditor

        var id: Int { rawValue }
    }

    @Published var currentSheet: Sheet?
}
