//
//  ScreenView.swift
//  ControlRoom
//
//  Created by Moritz Schaub on 18.05.20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Controls screenshots and videos of the simulator
struct ScreenView: View {
    /// Store the local settings for screenshots
    private struct Screenshot {
        var type: SimCtl.IO.ImageFormat
        var display: SimCtl.IO.Display?
        var mask: SimCtl.IO.Mask?
    }

    var simulator: Simulator

    @State private var screenshot = Screenshot(type: .png, display: .none, mask: .none)

    var body: some View {
        Form {
            Group {
                Section(header: Text("Screenshot")) {
                    Picker("Format:", selection: self.$screenshot.type) {
                        ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                            Text(type.rawValue.uppercased()).tag(type)
                        }
                    }

                    if simulator.deviceFamily == .iPad || simulator.deviceFamily == .iPhone {
                        Picker("Display:", selection: self.$screenshot.display) {
                            ForEach(SimCtl.IO.Display.all, id: \.self) { display in
                                Text(display?.rawValue ?? "none").tag(display)
                            }
                        }
                    }

                    Picker("Mask:", selection: self.$screenshot.mask) {
                        ForEach(SimCtl.IO.Mask.all, id: \.self) { mask in
                            Text(mask?.rawValue ?? "none").tag(mask)
                        }
                    }

                    Button(action: takeScrenshot) {
                        Text("Take Screenshot")
                    }

                    FormSpacer()
                }
            }

            Spacer()
        }.tabItem {
            Text("Screen")
        }
        .padding()
    }

    init(simulator: Simulator) {
        self.simulator = simulator
    }

    /// Takes a screenshot of the device's current screen and saves it to the desktop.
    func takeScrenshot() {
        SimCtl.saveScreenshot(simulator.id, to: makeScreenshotFilename(), type: self.screenshot.type, display: self.screenshot.display, with: self.screenshot.mask)
    }

    /// Creates a filename for a screenshot that ought to be unique
    func makeScreenshotFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"
        let dateString = formatter.string(from: Date())
        return "~/Desktop/ControlRoom-\(dateString).\(self.screenshot.type.rawValue)"
    }
}

struct ScreenshotAndRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenView(simulator: .example)
    }
}
