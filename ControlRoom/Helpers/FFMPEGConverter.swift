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
        var audioBitrate = "128k"

        var arguments: [String] {
            [
                "-i", inPath,
                "-codec:v", "libx264",
                "-b:v", videoBitrate,
                "-filter:v", "fps=\(fps)",
                "-crf", "\(videoQuality.crf)",
                "-bf", "2",
                "-flags", "+cgop",
                "-pix_fmt", "yuv420p",
                "-codec:a", "mp3",
                "-strict",
                "-2",
                "-b:a", audioBitrate,
                "-r:a", "48000",
                "-movflags", "faststart",
                outPath
            ]
        }
    }

    static let available: Bool = {
        FileManager.default.fileExists(atPath: launchPath)
    }()

    static func convert(input inPath: String, output outPath: String,
                        callback: @escaping (Result<Void, CommandLineError>) -> Void) {
        execute(Command(inPath: inPath, outPath: outPath)) { result in
            switch result {
            case .success:
                callback(.success(()))
            case .failure(let error):
                callback(.failure(error))
            }
        }
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
