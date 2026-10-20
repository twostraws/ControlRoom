import Foundation
import ImageIO

extension PosterBoardController {
    // Use Collections' Still renderer. A higher contentVersion prevents WallpaperKit
    // from silently substituting the built-in preset with the same identifier.
    // Commit the manifest only after its referenced image has been encoded.
    static func replaceArtwork(in bundleURL: URL, imageURL: URL) throws {
        let manager = FileManager.default
        let manifestURL = bundleURL.appendingPathComponent("Wallpaper.plist")
        let originalURL = bundleURL.appendingPathComponent(".ControlRoomOriginalWallpaper.plist")
        let manifest = try readManifest(manifestURL)
        guard bundleURL.pathExtension == "wallpaper", manifest["assets"] is [String: Any] else {
            throw OperationError(message: "This provider does not contain replaceable wallpaper artwork.")
        }
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 4096
              ] as CFDictionary) else {
            throw OperationError(message: "The selected file could not be read as an image.")
        }
        let filename = "ControlRoomImage-\(UUID().uuidString).jpg"
        let output = bundleURL.appendingPathComponent(filename)
        do {
            let encoded = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(encoded, "public.jpeg" as CFString, 1, nil) else {
                throw OperationError(message: "The wallpaper image could not be prepared.")
            }
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw OperationError(message: "The wallpaper image could not be encoded.") }
            try (encoded as Data).write(to: output, options: .atomic)
            var updated = manifest
            let asset: [String: Any] = ["type": "Still", "fullSizeImageFileName": filename, "thumbnailImageFileName": filename,
                                         "identifier": manifest["identifier"] ?? 0, "name": "Image"]
            updated["assets"] = ["lockAndHome": ["default": asset, "dark": asset, "inactive": asset]]
            updated["appearanceAware"] = false
            updated["logicalScreenClass"] = "any"
            updated["disableAdaptiveTime"] = false
            updated["preferredProminentColor"] = ["default": "#FFFFFF", "dark": "#FFFFFF"]
            updated["contentVersion"] = max((manifest["contentVersion"] as? NSNumber)?.doubleValue ?? 1, 1) + 1
            if !manager.fileExists(atPath: originalURL.path) {
                try Data(contentsOf: manifestURL).write(to: originalURL, options: .atomic)
            }
            try PropertyListSerialization.data(fromPropertyList: updated, format: .xml, options: 0).write(to: manifestURL, options: .atomic)
        } catch {
            try? manager.removeItem(at: output)
            throw error
        }
        try removeGeneratedArtwork(in: bundleURL, except: filename)
    }

    static func restoreArtwork(in bundleURL: URL) throws {
        let manager = FileManager.default
        let original = bundleURL.appendingPathComponent(".ControlRoomOriginalWallpaper.plist")
        let data = try Data(contentsOf: original)
        _ = try readManifest(original)
        try data.write(to: bundleURL.appendingPathComponent("Wallpaper.plist"), options: .atomic)
        try removeGeneratedArtwork(in: bundleURL, except: nil)
        try manager.removeItem(at: original)
    }

    private static func removeGeneratedArtwork(in bundleURL: URL, except retained: String?) throws {
        let manager = FileManager.default
        for url in try manager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil) {
            let name = url.deletingPathExtension().lastPathComponent
            guard url.pathExtension == "jpg", name.hasPrefix("ControlRoomImage-"),
                  UUID(uuidString: String(name.dropFirst("ControlRoomImage-".count))) != nil,
                  url.lastPathComponent != retained else { continue }
            try requireContained(url, in: bundleURL)
            try manager.removeItem(at: url)
        }
    }

    static func clearSnapshots(in versionURL: URL) throws {
        let manager = FileManager.default
        for url in try manager.contentsOfDirectory(at: versionURL, includingPropertiesForKeys: nil) {
            guard url.lastPathComponent.hasPrefix("RuntimeSnapshot") || ["scratch", "FallbackSnapshots"].contains(url.lastPathComponent) else { continue }
            try requireContained(url, in: versionURL)
            try manager.removeItem(at: url)
        }
    }

}
