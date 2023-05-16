//
//  ColorsView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 16/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

struct ColorsView: View {
    enum ColorOption {
        case hex, swiftUI, uiKit
    }

    @State private var pickedColor = PickedColor.default

    @AppStorage("CRColorPickerAccuracy") var colorPickerAccuracy = 2
    @AppStorage("CRColorPickerUppercaseHex") var uppercaseHex = true

    @StateObject private var colorHistoryController = ColorHistoryController()
    @State private var previouslyPickedSelection: PickedColor.ID?

    var body: some View {
        VStack {
            Button {
                Task {
                    let selectedColor = await NSColorSampler().sample()

                    if let newPickedColor = colorHistoryController.add(selectedColor) {
                        previouslyPickedSelection = newPickedColor.id
                        pickedColor = newPickedColor
                    }
                }
            } label: {
                Label("Select Color", systemImage: "eyedropper")
            }

            if let pickedColor {
                HStack(spacing: 10) {
                    Circle()
                        .fill(pickedColor.swiftUIColor)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary, lineWidth: 1)
                        }
                        .frame(width: 50, height: 50)

                    Text(pickedColor.hex)
                        .font(.title)
                        .textCase(uppercaseHex ? .uppercase : .lowercase)
                        .textSelection(.enabled)
                }
                .draggable(assetCatalogData(for: pickedColor))
                .padding(10)

                Form {
                    LabeledContent("SwiftUI code:") {
                        Text(pickedColor.swiftUICode(roundedTo: colorPickerAccuracy))
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }

                    LabeledContent("UIKit code:") {
                        Text(pickedColor.uiKitCode(roundedTo: colorPickerAccuracy))
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                    }
                    .padding(.bottom, 10)
                }
            }

            Spacer()
                .frame(height: 40)

            Text("Previous Colors")
                .font(.headline)

            Table(of: PickedColor.self, selection: $previouslyPickedSelection.onChange(updatePickedColor)) {
                TableColumn("Color") { color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary, lineWidth: 1)
                        }
                        .frame(width: 24, height: 24)
                }
                .width(40)

                TableColumn("Hex") { color in
                    Text(color.hex)
                        .textCase(uppercaseHex ? .uppercase : .lowercase)
                }
            } rows: {
                // We create rows by hand so that we can attach an item
                // provider for dragging asset catalog color sets.
                ForEach(colorHistoryController.colors) { color in
                    TableRow(color)
                        .itemProvider {
                            let provider = NSItemProvider()
                            provider.register(assetCatalogData(for: color))
                            return provider
                        }
                }
            }

            HStack {
                Menu("Copy") {
                    Button("Hex String") {
                        copy(as: .hex)
                    }

                    Button("SwiftUI Code") {
                        copy(as: .swiftUI)
                    }

                    Button("UIKit Code") {
                        copy(as: .uiKit)
                    }
                }
                .menuIndicator(.hidden)
                .fixedSize()

                Button("Delete", action: deletePreviouslySelected)
            }
            .disabled(previouslyPickedSelection == nil)

            Text("**Tip:** You can drag any of the colors from here directly into an Xcode asset catalog ✨")
                .padding(.top, 20)
        }
        .padding()
        .tabItem {
            Text("Colors")
        }
    }

    /// Updates the top area picked color to match a historical picked color
    func updatePickedColor() {
        pickedColor = colorHistoryController.item(with: previouslyPickedSelection) ?? .default
    }

    /// Copies a color option to the clipboard using various available formats.
    func copy(as option: ColorOption) {
        guard let id = previouslyPickedSelection else { return }
        guard let pickedColor = colorHistoryController.item(with: id) else { return }

        let colorString: String

        switch option {
        case .hex:
            if uppercaseHex {
                colorString = pickedColor.hex.uppercased()
            } else {
                colorString = pickedColor.hex.lowercased()
            }
        case .swiftUI:
            colorString = pickedColor.swiftUICode(roundedTo: colorPickerAccuracy)
        case .uiKit:
            colorString = pickedColor.uiKitCode(roundedTo: colorPickerAccuracy)
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(colorString, forType: .string)
    }

    func deletePreviouslySelected() {
        colorHistoryController.delete(previouslyPickedSelection)
        previouslyPickedSelection = nil
    }

    func assetCatalogData(for color: PickedColor) -> URL {
        let saveDirectory = URL.temporaryDirectory.appending(path: "New Color.colorset")
        try? FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true)

        let colorSet = XcodeColorSet(red: color.hexRed, green: color.hexGreen, blue: color.hexBlue)

        let contentsURL = saveDirectory.appending(path: "Contents.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let encodedData = try? encoder.encode(colorSet)
        try? encodedData?.write(to: contentsURL)

        return saveDirectory
    }
}

struct ColorsView_Previews: PreviewProvider {
    static var previews: some View {
        ColorsView()
    }
}
