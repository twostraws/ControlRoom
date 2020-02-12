//
//  Binding-OnChange.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Two extensions to make it easier to respond to changes in a binding.
extension Binding {
    /// Updates the binding then calls a closure with the new value.
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
            }
        )
    }

    /// Updates the binding then calls a closure without the new value.
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler()
            }
        )
    }
}
