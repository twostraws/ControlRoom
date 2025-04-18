//
//  ColorPickerView.swift
//  ControlRoom
//
//  Created by Elliot Knight on 11/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI

struct ColorPickerView: View {
    /// Whether hex strings should be printed in uppercase or not.
    @AppStorage("CRColorPickerUppercaseHex") var uppercaseHex = true

    /// How many decimal places to use for rounding picked colors.
    @AppStorage("CRColorPickerAccuracy") var colorPickerAccuracy = 2

    var body: some View {
        VStack {
            Toggle("Uppercase Hex Strings", isOn: $uppercaseHex)
                .padding(.bottom)

            Text("Set the maximum number of decimal places to use when generating code for picked simulator colors. The default is 2.")
            Stepper("Decimal Places: \(colorPickerAccuracy)", value: $colorPickerAccuracy, in: 0...5)
                .pickerStyle(.segmented)
        }
    }
}

#Preview {
    ColorPickerView()
}
