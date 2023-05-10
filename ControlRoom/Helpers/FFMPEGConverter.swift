//
//  FFMPEGConverter.swift
//  ControlRoom
//
//  Created by Nikolay Volosatov on 2.04.21.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import Foundation

enum FFMPEGConverter: CommandLineCommandExecuter {
    static var launchPath = "/usr/local/bin/ffmpeg"

    struct Command: CommandLineCommand {
        var inPath: String
        var outPath: String

        var fps = 60
        var videoQuality = VideoQuality.default
        var videoBitrate = "2.0M"

        var arguments: [String] {
            [
                "-i", inPath,                   // Input file
                "-codec:v", "libx264",          // Video Codec: H.264
                "-b:v", videoBitrate,           // Limit video bitrate
                "-filter:v", "fps=\(fps)",      // Set video FPS
                "-crf", "\(videoQuality.crf)",  // Set H.264 compression quality (0 - 51, smaller better)
                "-c:a", "copy",                 // Copy audio as is
                outPath                         // Output file
            ]
        }

        var environmentOverrides: [String: String]? { nil }
    }

    static let available: Bool = {
        FileManager.default.fileExists(atPath: launchPath)
    }()

    static func convert(input inPath: String, output outPath: String,
                        callback: @escaping (Result<Void, CommandLineError>) -> Void) {
        let initialSize = fileSizeString(inPath)
        execute(Command(inPath: inPath, outPath: outPath)) { result in
            switch result {
            case .success:
                let resultSize = fileSizeString(outPath)
                print("Video Compressed: \(initialSize) -> \(resultSize)")
                callback(.success(()))
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    static private func fileSizeString(_ path: String) -> String {
        guard let sizeAttribute = try? FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size],
              let size = sizeAttribute as? UInt64
        else {
            return "?"
        }
        let sizeMb = Double(size) / 1024 / 1024
        return String(format: "%0.3f Mb", sizeMb)
    }
}

extension FFMPEGConverter {
    enum VideoQuality {
        case loseless
        case high
        case `default`
        case low
        case worstPossible
        case custom(Int)

        var crf: Int {
            switch self {
            case .loseless:
                return 0
            case .high:
                return 18
            case .default:
                return 23
            case .low:
                return 28
            case .worstPossible:
                return 51
            case .custom(let val):
                return val
            }
        }
    }
}
