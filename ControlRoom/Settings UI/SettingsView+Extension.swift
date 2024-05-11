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
    func makePickersForm() -> some View {
        Form {
            Picker("Screenshot Format:", selection: $captureSettings.imageFormat) {
                ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                    Text(type.rawValue.uppercased()).tag(type)
                }
            }

            Picker("Video Format:", selection: $captureSettings.videoFormat) {
                ForEach(SimCtl.IO.VideoFormat.all, id: \.self) { item in
                    if item == .divider {
                        Divider()
                    } else {
                        Text(item.name).tag(item)
                    }
                }
            }

            Picker("Display:", selection: $captureSettings.display) {
                ForEach(SimCtl.IO.Display.allCases, id: \.self) { display in
                    Text(display.rawValue.capitalized).tag(display)
                }
            }

            Picker("Mask:", selection: $captureSettings.mask) {
                ForEach(SimCtl.IO.Mask.allCases, id: \.self) { mask in
                    Text(mask.rawValue.capitalized).tag(mask)
                }
            }
            .disabled(renderChrome)

            Toggle(isOn: $renderChrome.onChange(updateChromeSettings)) {
                VStack(alignment: .leading) {
                    Text("Add device chrome to screenshots")
                    Text("This is an experimental feature and may not function properly yet.")
                        .font(.caption)
                }
            }
        }
    }

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
