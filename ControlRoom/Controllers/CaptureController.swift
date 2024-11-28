//
//  CaptureController.swift
//  ControlRoom
//
//  Created by Paul Hudson on 10/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Handles all screenshotting and video creation.
class CaptureController: ObservableObject {
    /// The user's settings for capturing
  @AppStorage("captureSettings") var settings = CaptureSettings(imageFormat: .png, videoFormat: .h264, display: .internal, mask: .ignored, saveURL: .desktop)

    /// The currently active recording process, if it exists. We don't need to monitor this, just keep it alive.
    @Published var recordingProcess: Process?

    /// The name of the file we're writing to, used at first in a temporary directory then on the desktop.
    @Published var recordingFilename = ""

    /// The export format description to be shown while exporting
    @Published var exportDescription = ""

    /// Converting MP4 to GIF takes time, so this tracks the progress of the operation
    @Published var exportProgress: CGFloat = 1.0

    private var videoFormat = SimCtl.IO.VideoFormat.h264

    var imageFormatString: String {
        settings.imageFormat.rawValue.uppercased()
    }

    var videoFormatString: String {
        settings.videoFormat.name
    }

    @MainActor
    /// Takes a screenshot of the device's current screen and saves it to the desktop.
    func takeScreenshot(of simulator: Simulator, format: SimCtl.IO.ImageFormat? = nil) {
        // If the user asked for a specific format then use it, otherwise
        // use whatever is our default.
        let resolvedFormat = format ?? settings.imageFormat

        // The filename where we intend to save this image
        let filename = makeScreenshotFilename(format: resolvedFormat)

        SimCtl.saveScreenshot(simulator.id, to: filename.path(), type: resolvedFormat, display: settings.display, with: settings.mask) { result in

            if UserDefaults.standard.bool(forKey: "renderChrome") {
                if let image = NSImage(contentsOf: filename) {
                    Task { @MainActor in
                        if let renderer = try? ChromeRenderer(deviceName: simulator.name, screenshot: image) {
                            let result = renderer.makeImage()

                            if let tiff = result?.tiffRepresentation {
                                let bitmap = NSBitmapImageRep(data: tiff)
                                if let compressedBitmap = bitmap?.representation(using: resolvedFormat.nsFileType, properties: [:]) {
                                    try FileManager.default.removeItem(at: filename)
                                    try compressedBitmap.write(to: filename)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Creates a filename for a screenshot that ought to be unique
    func makeScreenshotFilename(format: SimCtl.IO.ImageFormat) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd-HH-mm-ss"

        let dateString = formatter.string(from: Date.now)

      return settings.saveURL.url.appending(path: "ControlRoom-\(dateString).\(format.rawValue)")
    }

    /// Starts recording video of the device, saving it to the desktop.
    func startRecordingVideo(of simulator: Simulator, format: SimCtl.IO.VideoFormat? = nil) {
        // Store the format we've been asked to record in, so we can export to GIF
        // correctly later on.
        videoFormat = format ?? settings.videoFormat

        recordingFilename = makeVideoFilename()

        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename).path

        recordingProcess = SimCtl.startVideo(simulator.id, to: tempPath, type: .h264, display: settings.display, with: settings.mask)
    }

    func stopRecordingVideo() {
        recordingProcess?.interrupt()
        recordingProcess?.waitUntilExit()
        recordingProcess = nil

        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent(recordingFilename)

        let savePath = settings.saveURL.url.appendingPathComponent(recordingFilename).path

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
            let result = try await sourceURL.convertToGIF(maxSize: size) { [weak self] progress in
                self?.exportProgress = progress
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
        FFMPEGConverter.convert(input: sourceURL.path, output: convertPath) { [weak self] result in
            self?.exportProgress = 1.0
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
