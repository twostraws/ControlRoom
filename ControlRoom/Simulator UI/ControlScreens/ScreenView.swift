//
//  ScreenView.swift
//  ControlRoom
//
//  Created by Moritz Schaub on 18.05.20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import AVFoundation
import Foundation
import SwiftUI

/// A struct containing one video format's name and user-facing description.
struct VideoFormat {
    let name: String
    let description: String

    static let all = [
        VideoFormat(name: "H.264", description: "Saved at the natural resolution of the device."),
        VideoFormat(name: "GIF (Small)", description: "Up to 400px in either dimension."),
        VideoFormat(name: "GIF (Medium)", description: "Up to 800px in either dimension."),
        VideoFormat(name: "GIF (Large)", description: "Up to 1200px in either dimension."),
        VideoFormat(name: "GIF (Full)", description: "Saved at the natural resolution of the device. ⚠️ Warning: this creates very large files.")
    ]
}

/// Controls screenshots and videos of the simulator
struct ScreenView: View {
    /// Store the local settings for screenshots
    private struct Screenshot {
        var type: SimCtl.IO.ImageFormat
        var display: SimCtl.IO.Display?
        var mask: SimCtl.IO.Mask?
    }

    @EnvironmentObject var preferences: Preferences
    let simulator: Simulator

    /// The user's settings for a screenshot.
    @State private var screenshot = Screenshot(type: .png, display: .none, mask: .none)

    /// The currently active recording process, if it exists. We don't need to monitor this, just keep it alive.
    @State private var recordingProcess: Process?

    /// The name of the file we're writing to, used at first in a temporary directory then on the desktop.
    @State private var recordingFilename = ""

    /// Converting MP4 to GIF takes time, so this tracks the progress of the operation
    @State private var exportProgress: CGFloat = 1.0

    var body: some View {
        Form {
            Section(header: Text("Screenshot").font(.headline)) {
                Picker("Format:", selection: $screenshot.type) {
                    ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                        Text(type.rawValue.uppercased()).tag(type)
                    }
                }

                Button("Take Screenshot", action: takeScreenshot)

                FormSpacer()
            }

            Section(header: Text("Video").font(.headline)) {
                Picker("Format:", selection: $preferences.videoFormat) {
                    ForEach(0..<VideoFormat.all.count) { item in
                        Text(VideoFormat.all[item].name)
                    }
                }

                Text(VideoFormat.all[preferences.videoFormat].description)

                HStack {
                    Button(recordingProcess == nil ? "Start Recording" : "Stop Recording", action: toggleRecordingVideo)
                }

                FormSpacer()
            }

            Section(header:
                VStack(alignment: .leading) {
                    Text("Advanced options")
                        .font(.headline)
                    Text("Applies to both screenshots and videos")
                        .font(.caption)
                }
            ) {
                if simulator.deviceFamily == .iPad || simulator.deviceFamily == .iPhone {
                    Picker("Display:", selection: $screenshot.display) {
                        ForEach(SimCtl.IO.Display.all, id: \.self) { display in
                            Text(display?.rawValue.capitalized ?? "None").tag(display)
                        }
                    }
                }

                Picker("Mask:", selection: $screenshot.mask) {
                    ForEach(SimCtl.IO.Mask.all, id: \.self) { mask in
                        Text(mask?.rawValue.capitalized ?? "None").tag(mask)
                    }
                }
            }

            Spacer()

            if exportProgress != 1.0 {
                ProgressView("Exporting GIF", value: exportProgress, total: 1.0)
            }
        }.tabItem {
            Text("Screen")
        }
        .padding()
    }

    /// Takes a screenshot of the device's current screen and saves it to the desktop.
    func takeScreenshot() {
        SimCtl.saveScreenshot(simulator.id, to: makeScreenshotFilename(), type: screenshot.type, display: screenshot.display, with: screenshot.mask)
    }

    /// Either starts or stops recording video, depending on the current state
    func toggleRecordingVideo() {
        if recordingProcess == nil {
            startRecordingVideo()
        } else {
            stopRecordingVideo()
        }
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

        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename)

        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        let savePath = paths[0].appendingPathComponent(recordingFilename).path

        let format = VideoFormat.all[preferences.videoFormat].name

        if format.hasPrefix("GIF") {
            var size: CGFloat?

            if format.contains("Small") {
                size = 400
            } else if format.contains("Medium") {
                size = 800
            } else if format.contains("Large") {
                size = 1200
            }

            let gifExtension = savePath.replacingOccurrences(of: ".mp4", with: ".gif")

            sourceURL.convertToGIF(maxSize: size) { progress in
                exportProgress = progress
            } completion: { result in
                switch result {
                case .success(let gifURL):
                    try? FileManager.default.moveItem(atPath: gifURL.path, toPath: gifExtension)
                case .failure(let reason):
                    print(reason.localizedDescription)
                }
            }
        } else {
            try? FileManager.default.moveItem(atPath: sourceURL.path, toPath: savePath)
        }
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
