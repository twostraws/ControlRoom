//
//  AVAssetToGIF.swift
//  ControlRoom
//
//  Created by Paul Hudson on 29/01/2021.
//  Copyright © 2021 Daniel Farrelly, Nathan Lawrence, and Christian Selig.
//  All rights reserved.
//

import AVFoundation
import Foundation

enum GIFError: Error {
    case unableToReadFile
    case unableToFindTrack
    case unableToCreateOutput
    case unknown
}

extension URL {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func convertToGIF(maxSize cappedResolution: CGFloat?, updateProgress: @escaping (CGFloat) -> Void, completion: @escaping (Result<URL, GIFError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: self)

            guard let reader = try? AVAssetReader(asset: asset) else {
                completion(.failure(.unableToReadFile))
                return
            }

            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                completion(.failure(.unableToFindTrack))
                return
            }

            let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)

            let aspectRatio = videoSize.width / videoSize.height
            let resultingSize: CGSize

            if let cappedResolution = cappedResolution {
                if videoSize.width > videoSize.height {
                    let cappedWidth = round(min(cappedResolution, videoSize.width))
                    resultingSize = CGSize(width: cappedWidth, height: round(cappedWidth / aspectRatio))
                } else {
                    let cappedHeight = round(min(cappedResolution, videoSize.height))
                    resultingSize = CGSize(width: round(cappedHeight * aspectRatio), height: cappedHeight)
                }
            } else {
                resultingSize = CGSize(width: videoSize.width, height: videoSize.height)
            }

            let duration: CGFloat = CGFloat(asset.duration.seconds)
            let nominalFrameRate = CGFloat(videoTrack.nominalFrameRate)
            let nominalTotalFrames = Int(round(duration * nominalFrameRate))
            let desiredFrameRate: CGFloat = 15.0

            // In order to convert from, say 30 FPS to 20, we'd need to remove 1/3 of the frames, this applies that math and decides which frames to remove/not process

            let framesToRemove = calculateFramesToRemove(desiredFrameRate: desiredFrameRate, nominalFrameRate: nominalFrameRate, nominalTotalFrames: nominalTotalFrames)

            let totalFrames = nominalTotalFrames - framesToRemove.count

            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: resultingSize.width,
                kCVPixelBufferHeightKey as String: resultingSize.height
            ]

            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)

            reader.add(readerOutput)
            reader.startReading()

            // An array where each index corresponds to the delay for that frame in seconds.
            // Note that since it's regarding frames, the first frame would be the 0th index in the array.
            let frameDelays = calculateFrameDelays(desiredFrameRate: desiredFrameRate, nominalFrameRate: nominalFrameRate, totalFrames: totalFrames)

            // Since there can be a disjoint mapping between frame delays
            // and the frames in the video/pixel buffer (if we're lowering
            // the
            // frame rate) rather than messing around with a complicated mapping,
            // just have a stack where we pop frame delays off as we use them
            var appliedFrameDelayStack = frameDelays

            var sample: CMSampleBuffer? = readerOutput.copyNextSampleBuffer()

            let fileProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFLoopCount as String: 0
                ]
            ]

            let resultingFilename = "Image.gif"
            let resultingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(resultingFilename)

            if FileManager.default.fileExists(atPath: resultingFileURL.path) {
                do {
                    try FileManager.default.removeItem(at: resultingFileURL)
                } catch {
                    // "GIF file already exists in temp directory, error deleting: \(error)"
                }
            }

            guard let destination = CGImageDestinationCreateWithURL(resultingFileURL as CFURL, kUTTypeGIF, totalFrames, nil) else {
                completion(.failure(.unableToCreateOutput))
                return
            }

            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1

            var framesCompleted = 0

            // Refers index refers to the frame index in the actual video/pixel buffer,
            // rather than the frames we may actually be deciding to use for the GIF.
            var currentFrameIndex = 0

            while sample != nil {
                currentFrameIndex += 1

                if framesToRemove.contains(currentFrameIndex) {
                    sample = readerOutput.copyNextSampleBuffer()
                    continue
                }

                // Should probably look into why the delay stack would be empty here, but
                // I assume it's just a total frames reporting issue with AVFoundation and
                // this seems to work fine.
                guard appliedFrameDelayStack.isNotEmpty else { break }

                // See description of frame delay stack above
                let frameDelay = appliedFrameDelayStack.removeFirst()

                if let newSample = sample {
                    // Create it as an optional and manually nil it out every time it's
                    // finished otherwise weird Swift bug where memory will balloon enormously
                    // (see https://twitter.com/ChristianSelig/status/1241572433095770114)
                    var cgImage: CGImage? = self.cgImageFromSampleBuffer(newSample)

                    operationQueue.addOperation {
                        framesCompleted += 1

                        if let cgImage = cgImage {
                            let frameProperties: [String: Any] = [
                                kCGImagePropertyGIFDictionary as String: [
                                    kCGImagePropertyGIFDelayTime: frameDelay
                                ]
                            ]

                            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
                        }

                        cgImage = nil

                        let progress = CGFloat(framesCompleted) / CGFloat(totalFrames)

                        // GIF progress is a little fudged so it works with downloading progress reports
                        DispatchQueue.main.async {
                            updateProgress(progress)
                        }
                    }
                }

                sample = readerOutput.copyNextSampleBuffer()
            }

            operationQueue.waitUntilAllOperationsAreFinished()

            let didCreateGIF = CGImageDestinationFinalize(destination)

            guard didCreateGIF else {
                completion(.failure(.unknown))
                return
            }

            completion(.success(resultingFileURL))
        }
    }

    private func cgImageFromSampleBuffer(_ buffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let base = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(data: base, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytes, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info) else {
            return nil
        }

        let image = context.makeImage()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        return image
    }

    private func calculateFramesToRemove(desiredFrameRate: CGFloat, nominalFrameRate: CGFloat, nominalTotalFrames: Int) -> [Int] {
        // Ensure the actual/nominal frame rate isn't already lower than the desired, in which case don't even worry about it
        // Add a buffer of 2 so if it's close it won't freak out and cause a bunch of unnecessary conversion due to being so close
        if desiredFrameRate < nominalFrameRate - 2 {
            let percentageOfFramesToRemove = 1.0 - (desiredFrameRate / nominalFrameRate)
            let totalFramesToRemove = Int(round(CGFloat(nominalTotalFrames) * percentageOfFramesToRemove))

            // We should remove a frame every `frameRemovalInterval` frames…
            // Since we can't remove e.g.: the 3.7th frame, round that up to 4, and we'd remove the 4th frame, then the 7.4th -> 7th, etc.
            let frameRemovalInterval = CGFloat(nominalTotalFrames) / CGFloat(totalFramesToRemove)

            var framesToRemove: [Int] = []
            var sum: CGFloat = 0.0

            while sum <= CGFloat(nominalTotalFrames) {
                sum += frameRemovalInterval
                let roundedFrameToRemove = Int(round(sum))
                framesToRemove.append(roundedFrameToRemove)
            }

            return framesToRemove
        } else {
            return []
        }
    }

    func calculateFrameDelays(desiredFrameRate: CGFloat, nominalFrameRate: CGFloat, totalFrames: Int) -> [CGFloat] {
        // The GIF spec per W3 only allows hundredths of a second, which negatively
        // impacts our precision, so implement variable length delays to adjust for
        // more precision (https://www.w3.org/Graphics/GIF/spec-gif89a.txt).
        //
        // In other words, if we'd like a 0.033 frame delay, the GIF spec would treat
        // it as 0.03, causing our GIF to be shorter/sped up, in order to get around
        // this make 70% of the frames 0.03, and 30% 0.04.
        //
        // In this section, determine the ratio of frames ceil'd to the next hundredth, versus the amount floor'd to the current hundredth.
        let desiredFrameDelay: CGFloat = 1.0 / min(desiredFrameRate, nominalFrameRate)
        let flooredHundredth: CGFloat = floor(desiredFrameDelay * 100.0) / 100.0 // AKA "slow frame delay"
        let remainder = desiredFrameDelay - flooredHundredth
        let nextHundredth = flooredHundredth + 0.01 // AKA "fast frame delay"
        let percentageOfNextHundredth = remainder / 0.01
        let percentageOfCurrentHundredth = 1.0 - percentageOfNextHundredth

        let totalSlowFrames = Int(round(CGFloat(totalFrames) * percentageOfCurrentHundredth))

        // Now determine how they should be distributed, we obviously don't just
        // want all the longer ones at the end (would make first portion feel fast,
        // second part feel slow), so evenly distribute them along the GIF timeline.
        //
        // Determine the spacing in relation to slow frames, so for instance if it's 1.7, the round(1.7) = 2nd frame would be slow, then the round(1.7 * 2) = 3rd frame would be slow, etc.
        let spacingInterval = CGFloat(totalFrames) / CGFloat(totalSlowFrames)

        // Initialize it to start with all the fast frame delays, and then we'll identify which ones will be slow and modify them in the loop to follow
        var frameDelays: [CGFloat] = [CGFloat](repeating: nextHundredth, count: totalFrames)
        var sum: CGFloat = 0.0

        while sum <= CGFloat(totalFrames) {
            sum += spacingInterval
            let slowFrame = Int(round(sum))

            // Confusingly (for us), frames are indexed from 1, while the array in Swift is indexed from 0
            if slowFrame - 1 < totalFrames {
                frameDelays[slowFrame - 1] = flooredHundredth
            }
        }

        return frameDelays
    }
}
