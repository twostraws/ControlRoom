//
//  UIState.swift
//  ControlRoom
//
//  Created by Dave DeLong on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Combine

class UIState: ObservableObject {
    enum Sheet: Int, Identifiable {
        case preferences
        case createSimulator
        case notificationEditor

        var id: Int { rawValue }
    }

    enum Alert: Int, Identifiable {
        case confirmDeleteUnavailable

        var id: Int { rawValue }
    }

    static let shared = UIState()
    @Published var currentSheet: Sheet?
    @Published var currentAlert: Alert?

    private init() { }
}
