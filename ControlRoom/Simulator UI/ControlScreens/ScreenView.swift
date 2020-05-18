//
//  ScreenView.swift
//  ControlRoom
//
//  Created by Moritz Schaub on 18.05.20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

///controlls the Screen
struct ScreenView: View {
    private struct Screenshot {
        var type: SimCtl.IO.ImageFormat
        var display: SimCtl.IO.Display?
        var mask: SimCtl.IO.Mask?
    }

    private struct ScreenRecording {
        var codec: SimCtl.IO.Codec
        var display: SimCtl.IO.Display?
        var mask: SimCtl.IO.Mask?

    }
    var simulator: Simulator

    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var counter = 0.0
    @State private var recordButtonText = "Start Recording"
    @State private var isRecording = false

    @State private var screenshot = Screenshot(type: .png, display: .none, mask: .none)
    @State private var screenRecording = ScreenRecording(codec: .hevc, display: .none, mask: .none)

    var body: some View {
        Form {
            Group {
                Section(header: Text("Screenshot")) {
                    Picker("Format:", selection: self.$screenshot.type) {
                        ForEach(SimCtl.IO.ImageFormat.all, id: \.self) { type in
                            Text(type.rawValue).tag(type)
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

            Group {
                Section(header: Text("Screen recording")) {
                    Picker("Codec:", selection: self.$screenRecording.codec) {
                        ForEach(SimCtl.IO.Codec.all, id: \.self) { codec in
                            Text(codec.rawValue).tag(codec)
                        }
                    }

                    if simulator.deviceFamily == .iPad || simulator.deviceFamily == .iPhone {
                        Picker("Display:", selection: self.$screenRecording.display) {
                            ForEach(SimCtl.IO.Display.all, id: \.self) { display in
                                Text(display?.rawValue ?? "none").tag(display)
                            }
                        }
                    }

                    Picker("Mask:", selection: self.$screenRecording.mask) {
                        ForEach(SimCtl.IO.Mask.all, id: \.self) { mask in
                            Text(mask?.rawValue ?? "none").tag(mask)
                        }
                    }

                    Button(action: record) {
                        Text(recordButtonText)
                            .onReceive(timer) { _ in
                                if self.isRecording {
                                    self.counter += 0.1
                                    self.recordButtonText = String(format: "%.2f", self.counter)
                                }
                        }
                        .animation(.spring())
                    }
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

    func record() {
        if !self.isRecording {
            //SimCtl.recordVideo(simulator.id, to: makeScreenRecordingFilename(), codec: self.screenRecording.codec, display: self.screenRecording.display, with: self.screenRecording.mask)
            self.isRecording = true
        } else {
            self.isRecording = true
            self.timer.upstream.connect().cancel()
            self.counter = 0
            self.recordButtonText = "Start Recording"
        }
    }

    // Creates a filename for a screen recording that ought to be unique
    func makeScreenRecordingFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"
        let dateString = formatter.string(from: Date())
        return "~/Desktop/ControlRoom-\(dateString).mov"
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
