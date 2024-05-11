//
//  SettingsView+Extension.swift
//  ControlRoom
//
//  Created by Elliot Knight on 06/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI
import KeyboardShortcuts

// MARK: - Extracted Views

extension SettingsView {
    func makeColorPicker() -> some View {
        VStack {
            Toggle("Uppercase Hex Strings", isOn: $uppercaseHex)
                .padding(.bottom)

            Text("Set the maximum number of decimal places to use when generating code for picked simulator colors. The default is 2.")
            Stepper("Decimal Places: \(colorPickerAccuracy)", value: $colorPickerAccuracy, in: 0...5)
                .pickerStyle(.segmented)
        }
    }
}
