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
        VideoFormat(name: "GIF (Full)", description: "Saved at the natural resolution of the device. ⚠️ Warning: this creates very large files."),
        VideoFormat(name: "H.264 (Compressed)", description: "Compressed video with the original device resolution. Requires `ffmpeg` tool to be installed.")
    ]
}

/// Controls screenshots and videos of the simulator
struct ScreenView: View {
    let simulator: Simulator

    /// The user's settings for a screenshot.
    @AppStorage("screenshot") var screenshot = Screenshot(type: .png, display: .internal, mask: .ignored)

    /// The currently active recording process, if it exists. We don't need to monitor this, just keep it alive.
    @State private var recordingProcess: Process?

    /// The name of the file we're writing to, used at first in a temporary directory then on the desktop.
    @State private var recordingFilename = ""

    /// The export format description to be shown while exporting
    @State private var exportDescription = ""

    /// Converting MP4 to GIF takes time, so this tracks the progress of the operation
    @State private var exportProgress: CGFloat = 1.0

    @AppStorage("CRMedia_VideoFormat") private var videoFormat = 0

    var body: some View {
        Form {
            Section(header: Text("Screenshot").font(.headline)) {
                Picker("Format:", selection: $screenshot.type) {
                    ForEach(SimCtl.IO.ImageFormat.allCases, id: \.self) { type in
                        Text(type.rawValue.uppercased()).tag(type)
                    }
                }

                Button("Take Screenshot", action: takeScreenshot)

                Divider()
            }

            Section(header: Text("Video").font(.headline)) {
                Picker("Format:", selection: $videoFormat) {
                    ForEach(0..<VideoFormat.all.count, id: \.self) { item in
                        Text(VideoFormat.all[item].name)
                    }
                }

                Text(VideoFormat.all[videoFormat].description)

                HStack {
                    Button(recordingProcess == nil ? "Start Recording" : "Stop Recording", action: toggleRecordingVideo)
                }

                Divider()
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
                        ForEach(SimCtl.IO.Display.allCases, id: \.self) { display in
                            Text(display.rawValue.capitalized).tag(display)
                        }
                    }
                }

                Picker("Mask:", selection: $screenshot.mask) {
                    ForEach(SimCtl.IO.Mask.allCases, id: \.self) { mask in
                        Text(mask.rawValue.capitalized).tag(mask)
                    }
                }
            }

            Spacer()

            if exportProgress != 1.0 {
                ProgressView("Exporting \(exportDescription)", value: exportProgress, total: 1.0)
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

        let format = VideoFormat.all[videoFormat].name

        if format.hasPrefix("GIF") {
            exportGif(format, savePath, sourceURL)
        } else if format.contains("Compressed") {
            exportCompressedVideo(savePath, sourceURL)
        } else {
            try? FileManager.default.moveItem(atPath: sourceURL.path, toPath: savePath)
        }
    }

    /// Saves recorded video as a GIF-file
    private func exportGif(_ format: String, _ savePath: String, _ sourceURL: URL) {
        let size: CGFloat?

        if format.contains("Small") {
            size = 400
        } else if format.contains("Medium") {
            size = 800
        } else if format.contains("Large") {
            size = 1200
        } else {
            size = 1600
        }

        let gifExtension = savePath.replacingOccurrences(of: ".mp4", with: ".gif")

        exportDescription = "GIF"

        Task {
            let result = try await sourceURL.convertToGIF(maxSize: size) { progress in
                exportProgress = progress
            }

            switch result {
            case .success(let gifURL):
                try? FileManager.default.moveItem(atPath: gifURL.path, toPath: gifExtension)
            case .failure(let reason):
                print(reason.localizedDescription)
            }
        }
    }

    /// Compresses recorded video with `ffmpeg` before saving
    private func exportCompressedVideo(_ savePath: String, _ sourceURL: URL) {
        guard FFMPEGConverter.available else {
            try? FileManager.default.moveItem(atPath: sourceURL.path, toPath: savePath)
            print("The 'ffmpeg' isn't available.")
            return
        }

        let convertPath = sourceURL.path.appending("-compressed.mp4")
        exportDescription = "Compressed Video"
        exportProgress = 0.0
        FFMPEGConverter.convert(input: sourceURL.path, output: convertPath) { result in
            exportProgress = 1.0
            switch result {
            case .success:
                try? FileManager.default.moveItem(atPath: convertPath, toPath: savePath)
            case .failure(let reason):
                print(reason.localizedDescription)
            }
        }
    }

    /// Creates a filename for a screenshot that ought to be unique
    func makeScreenshotFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date.now)

        return "~/Desktop/ControlRoom-\(dateString).\(screenshot.type.rawValue)"
    }

    /// Creates a filename for a video that ought to be unique
    func makeVideoFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date.now)

        return "ControlRoom-\(dateString).mp4"
    }
}

/// Store the local settings for screenshots
struct Screenshot {
    var type: SimCtl.IO.ImageFormat
    var display: SimCtl.IO.Display
    var mask: SimCtl.IO.Mask
}

extension Screenshot: RawRepresentable {
    public init(rawValue: String) {
        let components = rawValue.components(separatedBy: "~")

        guard components.count == 3 else {
            type = .png
            display = .internal
            mask = .ignored
            return
        }

        type = SimCtl.IO.ImageFormat(rawValue: components[0]) ?? .png
        display = SimCtl.IO.Display(rawValue: components[1]) ?? .internal
        mask = SimCtl.IO.Mask(rawValue: components[2]) ?? .ignored
    }

    public var rawValue: String {
        let result = "\(type.rawValue)~\(display.rawValue)~\(mask.rawValue)"
        return result
    }
}

struct ScreenshotAndRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenView(simulator: .example)
            .environmentObject(Preferences())
    }
}
