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

    let simulator: Simulator

    /// The user's settings for a screenshot.
    @State private var screenshot = Screenshot(type: .png, display: .none, mask: .none)

    /// The currently active recording process, if it exists. We don't need to monitor this, just keep it alive.
    @State private var recordingProcess: Process?

    /// The name of the file we're writing to, used at first in a temporary directory then on the desktop.
    @State private var recordingFilename = ""

    var body: some View {
        Form {
            Group {
                Section(header: Text("Screenshot")) {
                    Picker("Format:", selection: $screenshot.type) {
                        ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                            Text(type.rawValue.uppercased()).tag(type)
                        }
                    }

                    if simulator.deviceFamily == .iPad || simulator.deviceFamily == .iPhone {
                        Picker("Display:", selection: $screenshot.display) {
                            ForEach(SimCtl.IO.Display.all, id: \.self) { display in
                                Text(display?.rawValue ?? "none").tag(display)
                            }
                        }
                    }

                    Picker("Mask:", selection: $screenshot.mask) {
                        ForEach(SimCtl.IO.Mask.all, id: \.self) { mask in
                            Text(mask?.rawValue ?? "none").tag(mask)
                        }
                    }

                    Button("Take Screenshot", action: takeScreenshot)

                    Button("Start Video", action: startRecordingVideo)
                        .disabled(recordingProcess != nil)

                    Button("Stop Video", action: stopRecordingVideo)
                        .disabled(recordingProcess == nil)

                    FormSpacer()
                }
            }

            Spacer()
        }.tabItem {
            Text("Screen")
        }
        .padding()
    }

    /// Takes a screenshot of the device's current screen and saves it to the desktop.
    func takeScreenshot() {
        SimCtl.saveScreenshot(simulator.id, to: makeScreenshotFilename(), type: screenshot.type, display: screenshot.display, with: screenshot.mask)
    }

    /// Starts recording video of the device, saving it to the desktop.
    func startRecordingVideo() {
        recordingFilename = makeVideoFilename()

        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename).path

        recordingProcess = SimCtl.startVideo(simulator.id, to: tempPath, type: .h264, display: screenshot.display, with: screenshot.mask)
    }

    func stopRecordingVideo() {
        recordingProcess?.interrupt()
        recordingProcess?.waitUntilExit()
        recordingProcess = nil

        let sourcePath = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename).path

        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        let savePath = paths[0].appendingPathComponent(recordingFilename).path

        try? FileManager.default.moveItem(atPath: sourcePath, toPath: savePath)
    }

    /// Creates a filename for a screenshot that ought to be unique
    func makeScreenshotFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date())

        return "~/Desktop/ControlRoom-\(dateString).\(screenshot.type.rawValue)"
    }

    /// Creates a filename for a video that ought to be unique
    func makeVideoFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date())

        return "ControlRoom-\(dateString).mp4"
    }
}

struct ScreenshotAndRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenView(simulator: .example)
    }
}
