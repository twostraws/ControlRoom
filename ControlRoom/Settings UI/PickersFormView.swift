//
//  PickersFormView.swift
//  ControlRoom
//
//  Created by Elliot Knight on 11/05/2024.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import SwiftUI

struct PickersFormView: View {
    /// The user's settings for capturing
    @AppStorage("captureSettings") var captureSettings = CaptureSettings(imageFormat: .png, videoFormat: .h264, display: .internal, mask: .ignored, saveURL: .desktop)

    /// Whether the user wants us to render device bezels around their screenshots.
    /// Note: this requires a mask of alpha, so we enforce that when true.
    @AppStorage("renderChrome") var renderChrome = false
    @State private var showFileImporter = false

    var body: some View {
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

          Button("Save to: \(captureSettings.saveURL.rawValue)") {
            showFileImporter = true
          }

            Toggle(isOn: $renderChrome.onChange(updateChromeSettings)) {
                VStack(alignment: .leading) {
                    Text("Add device chrome to screenshots")
                    Text("This is an experimental feature and may not function properly yet.")
                        .font(.caption)
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.directory]) { result in
          switch result {
          case .success(let success):
            captureSettings.saveURL = .other(success)
          case .failure:
            captureSettings.saveURL = .desktop
          }
        }
    }

    private func updateChromeSettings() {
        if renderChrome {
            captureSettings.mask = .alpha
        }
    }
}

#Preview {
    PickersFormView()
}
