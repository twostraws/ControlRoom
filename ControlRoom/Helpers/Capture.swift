//
//  Screenshot.swift
//  ControlRoom
//
//  Created by Paul Hudson on 08/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation

/// Store settings for video and screenshots
struct CaptureSettings {
    var imageFormat: SimCtl.IO.ImageFormat
    var videoFormat: SimCtl.IO.VideoFormat
    var display: SimCtl.IO.Display
    var mask: SimCtl.IO.Mask
    var saveURL: SimCtl.IO.SaveLocation
}

extension CaptureSettings: RawRepresentable {
    public init(rawValue: String) {
        let components = rawValue.components(separatedBy: "~")

        guard components.count == 5 else {
            imageFormat = .png
            videoFormat = .h264
            display = .internal
            mask = .ignored
            saveURL = .desktop
            return
        }

        imageFormat = SimCtl.IO.ImageFormat(rawValue: components[0]) ?? .png
        videoFormat = SimCtl.IO.VideoFormat(rawValue: components[1]) ?? .h264
        display = SimCtl.IO.Display(rawValue: components[2]) ?? .internal
        mask = SimCtl.IO.Mask(rawValue: components[3]) ?? .ignored
        saveURL = SimCtl.IO.SaveLocation(rawValue: components[4])
    }

    public var rawValue: String {
        let result = "\(imageFormat.rawValue)~\(videoFormat.rawValue)~\(display.rawValue)~\(mask.rawValue)~\(saveURL.rawValue)"
        return result
    }
}
