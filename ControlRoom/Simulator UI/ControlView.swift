//
//  ControlView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// The main tab view to control simulator settings.
struct ControlView: View {
    @ObservedObject var controller: SimulatorsController

    /// The user's settings for capturing
    @AppStorage("captureSettings") var captureSettings = CaptureSettings(imageFormat: .png, videoFormat: .h264, display: .internal, mask: .ignored)

    let simulator: Simulator
    let applications: [Application]

    /// The currently active recording process, if it exists. We don't need to monitor this, just keep it alive.
    @State private var recordingProcess: Process?

    /// The name of the file we're writing to, used at first in a temporary directory then on the desktop.
    @State private var recordingFilename = ""

    /// The export format description to be shown while exporting
    @State private var exportDescription = ""

    /// Converting MP4 to GIF takes time, so this tracks the progress of the operation
    @State private var exportProgress: CGFloat = 1.0

    @State private var videoFormat = SimCtl.IO.VideoFormat.h264

    var body: some View {
        TabView {
            SystemView(simulator: simulator)
            AppView(simulator: simulator, applications: applications)
            LocationView(controller: controller, simulator: simulator)
            StatusBarView(simulator: simulator)
            OverridesView(simulator: simulator)
        }
        .disabled(simulator.state != .booted)
        .navigationSubtitle("\(simulator.name) – \(simulator.runtime?.name ?? "Unknown OS")")
        .toolbar {
            Menu("Save \(captureSettings.imageFormat.rawValue.uppercased())") {
                Button("Save as PNG") {
                    takeScreenshot(format: .png)
                }

                Button("Save as JPEG") {
                    takeScreenshot(format: .jpeg)
                }

                Button("Save as TIFF") {
                    takeScreenshot(format: .tiff)
                }

                Button("Save as BMP") {
                    takeScreenshot(format: .bmp)
                }
            } primaryAction: {
                takeScreenshot(format: captureSettings.imageFormat)
            }

            if recordingProcess == nil {
                Menu("Record \(captureSettings.videoFormat.name)") {
                    ForEach(SimCtl.IO.VideoFormat.all, id: \.self) { item in
                        if item == .divider {
                            Divider()
                        } else {
                            Button("Save as \(item.name)") {
                                videoFormat = item
                                startRecordingVideo()
                            }
                        }
                    }
                } primaryAction: {
                    videoFormat = captureSettings.videoFormat
                    startRecordingVideo()
                }
            } else {
                Button("Stop Recording", action: stopRecordingVideo)
            }

            if simulator.state != .booted {
                Button("Boot", action: bootDevice)
            }

            if simulator.state != .shutdown {
                Button("Shutdown", action: shutdownDevice)
            }
        }
    }

    /// Launches the current device.
    func bootDevice() {
        SimCtl.boot(simulator.udid)
    }

    /// Terminates the current device.
    func shutdownDevice() {
        SimCtl.shutdown(simulator.udid)
    }

    /// Takes a screenshot of the device's current screen and saves it to the desktop.
    func takeScreenshot(format: SimCtl.IO.ImageFormat) {
        SimCtl.saveScreenshot(simulator.id, to: makeScreenshotFilename(format: format), type: format, display: captureSettings.display, with: captureSettings.mask)
    }

    /// Creates a filename for a screenshot that ought to be unique
    func makeScreenshotFilename(format: SimCtl.IO.ImageFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date.now)

        return "~/Desktop/ControlRoom-\(dateString).\(format.rawValue)"
    }

    /// Starts recording video of the device, saving it to the desktop.
    func startRecordingVideo() {
        recordingFilename = makeVideoFilename()

        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename).path

        recordingProcess = SimCtl.startVideo(simulator.id, to: tempPath, type: .h264, display: captureSettings.display, with: captureSettings.mask)
    }

    func stopRecordingVideo() {
        recordingProcess?.interrupt()
        recordingProcess?.waitUntilExit()
        recordingProcess = nil

        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename)

        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        let savePath = paths[0].appendingPathComponent(recordingFilename).path

        let format = videoFormat.name

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

    /// Creates a filename for a video that ought to be unique
    func makeVideoFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date.now)

        return "ControlRoom-\(dateString).mp4"
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(controller: .init(preferences: .init()),
                    simulator: .example,
                    applications: [])
            .environmentObject(Preferences())
    }
}
