//
//  ChromeRenderer.swift
//  ControlRoom
//
//  Created by Paul Hudson on 15/05/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import SwiftUI

// The programmer's credo: "We do these things not because they
// are easy, but because we thought they were going to be easy."
//                                        – @Pinboard
//
// This file was created late at night. "How hard could it be to
// add the simulator chrome around a screenshot?" I thought to
// myself at about 10:30pm. At midnight I knew the answer:
// bizarrely hard, because Apple stores information in various
// places, separated into individual PDFs, and pieced together
// using a JSON format I can only describe as "creative."
//
// Still, I persisted, and by about 1:30am I had produced the below.
// This code is terrible, partly because it digs into simulator
// files bundled with Xcode, partly because it doesn't support
// devices rotated to landscape, but mostly because it contains a
// huge amount of guesswork as to what individual components in
// Apple's file format actually mean.
//
// Yes, around 1am I did think to myself, "I should just use some
// pre-rendered pictures of each device," but I suspect Apple might
// have taken issue with that kind of thing!
//
// I would love to see this code ripped out and replaced with
// something actually sensible. I've documented what the below
// does in case it helps, but really it comes down to two things:
//
// 1. There's a large collection of simulator device types at
// /Applications/Xcode.app/Contents/Developer/Platforms
// /iPhoneOS.platform/Library/Developer/CoreSimulator
// /Profiles/DeviceTypes. These describe the various devices
// the simulator is capable of working with.
//
// 2. There's a collection of simulator chromes at
// /Applications/Xcode.app/Contents/Developer/Platforms
// /iPhoneOS.platform/Library/Developer/CoreSimulator
// /Profiles/Chrome. These provide PDFs for various parts
// of a simulator (top-left corner, top edge, top-right corner,
// etc), along with JSON that describes the positioning of
// those parts in a rather obtuse way.
//
// So, this code makes dozens of guesses about what the various
// pieces of JSON data mean, and attempts to use that to combine
// the PDF components together with a user screenshot to
// produce a final image. If there's a simpler, cleaner, or
// more flexible way to get the same result, I'd love to see it!

// Note: all the Decodable types for rendering are stored
// in ChromeRendererTypes.swift.

/// Renders a screenshot to an image using a specific device name.
class ChromeRenderer {
    /// The screenshot we want to place inside our device chrome.
    let screenshot: NSImage

    /// The base URL where we can find the JSON and images for this chrome.
    let baseURL: URL

    /// Describes the chrome type and screen scale for this simulator.
    let device: SimulatorDevice

    /// Describes the images and placements for this chrome.
    let chrome: SimulatorChrome

    /// The final width of the rendered image.
    let width: Double

    /// The final height of the rendered image.
    let height: Double

    /// Creates an instance of ChromeRenderer from a raw device name
    /// (eg "iPhone 14 Pro") and the screenshot the user just took.
    init(deviceName: String, screenshot: NSImage) throws {
        self.screenshot = screenshot

        // We start by loading this device's profile, which describes
        // what type of chrome we have and also the screen scale.
        var profileURL = URL(filePath: "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/DeviceTypes")
        profileURL.append(path: "\(deviceName).simdevicetype")
        profileURL.append(path: "/Contents/Resources/profile.plist")

        let profileData = try Data(contentsOf: profileURL)
        device = try PropertyListDecoder().decode(SimulatorDevice.self, from: profileData)

        // The main Chrome identifier looks like
        // com.apple.CoreSimulator.SimDeviceChrome.phone7, but we only want
        // the last part of that, i.e. "phone7".
        let mainIdentifier = device.chromeIdentifier.components(separatedBy: ".").last ?? "phone"

        // Now use that last part to find the PDFs and placement JSON.
        baseURL = URL(filePath: "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Chrome/\(mainIdentifier).simdevicechrome/Contents/Resources")

        let chromeURL = baseURL.appending(path: "chrome.json")
        let chromeData = try Data(contentsOf: chromeURL)

        chrome = try JSONDecoder().decode(SimulatorChrome.self, from: chromeData)

        // Add just a little extra space for padding
        width = (Double(screenshot.size.width) / device.mainScreenScale + chrome.images.sizing.leftWidth * 2) * 1.05
        height = (Double(screenshot.size.height) / Double(device.mainScreenScale) + chrome.images.sizing.topHeight * 2) * 1.05
    }

    /// This does all the actual work of loading and rendering the various image components to produce
    /// a final image of the screenshot in simulator chrome.
    @MainActor
    func makeImage() -> NSImage? {
        let renderer = ImageRenderer(content:
            Canvas { [self] context, size in
                // Loading the various edges of this chrome from PDFs – top-left,
                // left, top-right, and so on.
                // swiftlint:disable identifier_name
                let tl = image(named: chrome.images.topLeft)
                let l = image(named: chrome.images.left)
                let tr = image(named: chrome.images.topRight)
                let bl = image(named: chrome.images.bottomLeft)
                let r = image(named: chrome.images.right)
                let br = image(named: chrome.images.bottomRight)
                let t = image(named: chrome.images.top)
                let b = image(named: chrome.images.bottom)
                // swiftlint:enable identifier_name

                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // NSImage will report our screenshot's size at its full pixel
                // resolution, but we want to bring that down to the scale it
                // was actually rendered with – e.g. 3x.
                let screenshotSize = CGSize(width: screenshot.size.width / device.mainScreenScale, height: screenshot.size.height / device.mainScreenScale)

                // Presumably the size of the various edges of the device?
                let edgeSizes = SimulatorImagePadding(
                    top: chrome.images.sizing.topHeight,
                    left: chrome.images.sizing.leftWidth,
                    bottom: chrome.images.sizing.bottomHeight,
                    right: chrome.images.sizing.rightWidth
                )

                // Calculate base drawing positions of the four corners.
                let topLeft = CGPoint(x: size.width / 2 - (screenshotSize.width / 2), y: size.height / 2 - (screenshotSize.height / 2))
                let topRight = CGPoint(x: size.width / 2 + (screenshotSize.width / 2), y: topLeft.y)
                let bottomLeft = CGPoint(x: topLeft.x, y: size.height / 2 + (screenshotSize.height / 2))
                let bottomRight = CGPoint(x: topRight.x, y: bottomLeft.y)

                // Apple's PDFs provide device edges as being either 1-point high or 1-point wide,
                // depending on whether it's a horizontal or vertical edge. So, we need to stretch
                // the images to fit the correct dimensions for the current device.
                // NOTE: We overdraw ever so slightly to avoid hairline cracks between various segments.
                let drawHeight: Double = bottomLeft.y - t.size.height - b.size.height - topLeft.y + edgeSizes.top + edgeSizes.bottom + 2.0
                let drawWidth: Double = screenshotSize.width - tl.size.width - tr.size.width + edgeSizes.left + edgeSizes.right + 2.0

                // Now draw the inputs (i.e. buttons) that must be placed behind the rest of the
                // chrome, such as the volume buttons.
                let behindInputs = chrome.inputs.filter { $0.onTop == false }
                draw(inputs: behindInputs, in: context, canvasSize: size, screenshotSize: screenshotSize, edges: edgeSizes)

                // Draw the top and bottom edges of the chrome.
                let topX: Double = size.width / 2.0 - (screenshotSize.width / 2.0) + tl.size.width - edgeSizes.left - 1
                let topY: Double = topLeft.y - edgeSizes.top
                context.draw(Image(nsImage: t), in: CGRect(x: topX, y: topY, width: drawWidth, height: t.size.height))

                let bottomX: Double = size.width / 2 - (screenshotSize.width / 2.0) + tl.size.width - edgeSizes.left - 1
                let bottomY: Double = bottomLeft.y - b.size.height + edgeSizes.bottom
                context.draw(Image(nsImage: b), in: CGRect(x: bottomX, y: bottomY, width: drawWidth, height: b.size.height))

                // Draw the left and right edges of the chrome.
                context.draw(Image(nsImage: l), in: CGRect(x: topLeft.x - edgeSizes.left, y: topLeft.y + tl.size.height - edgeSizes.top - 1, width: l.size.width, height: drawHeight))
                context.draw(Image(nsImage: r), in: CGRect(x: topRight.x - tr.size.width + edgeSizes.right, y: topRight.y + tr.size.height - edgeSizes.top - 1, width: r.size.width, height: drawHeight))

                // Now draw the four corners. This must happen *after* the top, bottom, left,
                // and right edges have been drawn, because they overdraw by 1 pixel to avoid
                // hairline cracks. So, by rendering the actual corner images over the stretched
                // edges, we can make sure to overwrite the overdraw with correct pixel data
                // from the corner graphics.
                context.draw(Image(nsImage: tl), at: CGPoint(x: topLeft.x - edgeSizes.left, y: topLeft.y - edgeSizes.top), anchor: .topLeading)

                context.draw(Image(nsImage: tr), at: CGPoint(x: topRight.x + edgeSizes.right, y: topRight.y - edgeSizes.top), anchor: .topTrailing)

                context.draw(Image(nsImage: bl), at: CGPoint(x: bottomLeft.x - edgeSizes.left, y: bottomLeft.y + edgeSizes.bottom), anchor: .bottomLeading)

                context.draw(Image(nsImage: br), at: CGPoint(x: bottomRight.x + edgeSizes.right, y: bottomRight.y + edgeSizes.bottom), anchor: .bottomTrailing)

                // Now draw the inputs that must be placed *over* the rest of the
                // chrome, such as the home button.
                let onTopInputs = chrome.inputs.filter { $0.onTop == true }

                draw(inputs: onTopInputs, in: context, canvasSize: size, screenshotSize: screenshotSize, edges: edgeSizes)

                // Finally draw the user's screenshot over everything. This is automatically
                // rendered with the alpha cut out, so it should have rounded corners, a
                // Dynamic Island, and more.
                context.draw(Image(nsImage: screenshot), in: CGRect(x: center.x - screenshotSize.width / 2, y: center.y - screenshotSize.height / 2, width: screenshotSize.width, height: screenshotSize.height))
            }
            .frame(width: width, height: height)
        )

        renderer.scale = 2
        return renderer.nsImage
    }

    /// This method draws one set of input images to the canvas, which might be
    /// on top of or behind the rest of the chrome. This is where the seriously
    /// bad code lives, neatly isolated from the regular bad code that exists
    /// in the rest of this file. This was mostly produced through trial and error
    /// while trying to stay awake, so you can expect redundancy, extensive guesswork
    /// and a fair number of comedy mistakes too.
    func draw(inputs: [SimulatorImageInput], in context: GraphicsContext, canvasSize size: CGSize, screenshotSize: CGSize, edges: SimulatorImagePadding) {
        for input in inputs {
            let image = image(named: input.image)

            // The X position to draw this input
            // swiftlint:disable identifier_name
            let x: Double

            // The Y position to draw this input. This uses a default value
            // that works well for most inputs.
            var y = (size.height - screenshotSize.height) / 2.0 + Double(input.offsets.normal.y) + image.size.height / 2 - edges.top
            // swiftlint:enable identifier_name

            // The anchor to use to draw this input.
            let anchor: UnitPoint

            switch input.anchor {
            case "left":
                // This input is on the left edge of the device.
                x = (size.width - screenshotSize.width) / 2.0 - input.offsets.normal.x - edges.left + (chrome.images.devicePadding.left / 2.0)
                anchor = .leading

            case "right":
                // This input is on the right edge of the device.
                x = (size.width + screenshotSize.width) / 2.0 + input.offsets.normal.x + edges.left - (chrome.images.devicePadding.right / 2.0)
                anchor = .leading

            case "bottom":
                // This input is on the bottom of the device, such as
                // the home button.
                x = size.width / 2.0
                y = (size.height - screenshotSize.height) / 2.0 + (screenshotSize.height) + abs(input.offsets.normal.y)
                anchor = .bottom

            case "top":
                // This input is on the top of the device, such as the
                // power button on iPad.
                if input.align == "trailing" {
                    x = (size.width + screenshotSize.width) / 2.0 + input.offsets.normal.x + chrome.images.devicePadding.right
                } else {
                    x = (size.width / 2.0) + input.offsets.normal.x
                }

                y = (size.height - screenshotSize.height) / 2.0 - input.offsets.normal.y - chrome.images.devicePadding.top - image.size.height
                anchor = .bottom

            default:
                print("IMPORTANT: Unknown anchor for simulator image \(input.image)")
                x = 0
                anchor = .center
            }

            context.draw(Image(nsImage: image), at: CGPoint(x: x, y: y), anchor: anchor)
        }
    }

    /// Loads an image by combining our base URL with a particular PDF name.
    func image(named name: String) -> NSImage {
        let url = baseURL.appending(path: "\(name).pdf")
        return NSImage(contentsOf: url) ?? NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Missing image")!
    }
}
