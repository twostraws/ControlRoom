import Foundation

/// Offline operations on one simulator's PosterBoard store. No private frameworks are linked.
enum PosterBoardController {
    struct OperationError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private static let queue = DispatchQueue(label: "ControlRoom.PosterBoard", qos: .userInitiated)
    private static let storePath = "Library/Application Support/PRBPosterExtensionDataStore"

    struct WallpaperTemplate: Identifiable, Hashable {
        let bundleURL: URL
        let versionURL: URL
        let name: String
        let isGallery: Bool
        var id: String { bundleURL.path }
        var displayName: String { name }
        var canRestore: Bool {
            FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent(".ControlRoomOriginalWallpaper.plist").path)
        }
    }

    static func wallpaperTemplates(in dataURL: URL) throws -> [WallpaperTemplate] {
        let manager = FileManager.default
        let store = dataURL.appendingPathComponent(storePath)
        guard manager.fileExists(atPath: store.path) else { return [] }
        let structures = try manager.contentsOfDirectory(at: store, includingPropertiesForKeys: nil)
            .filter { Int($0.lastPathComponent) != nil }
            .sorted { (Int($0.lastPathComponent) ?? 0) > (Int($1.lastPathComponent) ?? 0) }
        guard let structure = structures.first else { return [] }
        var templates: [WallpaperTemplate] = []
        for category in ["configurations", "descriptors"] {
            let directory = structure.appendingPathComponent("Extensions/com.apple.WallpaperKit.CollectionsPoster/\(category)")
            guard manager.fileExists(atPath: directory.path) else { continue }
            for poster in try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
                guard UUID(uuidString: poster.lastPathComponent) != nil else { continue }
                let versions = try manager.contentsOfDirectory(at: poster.appendingPathComponent("versions"), includingPropertiesForKeys: nil)
                    .filter { Int($0.lastPathComponent) != nil }
                    .sorted { (Int($0.lastPathComponent) ?? 0) > (Int($1.lastPathComponent) ?? 0) }
                guard let version = versions.first else { continue }
                let contents = version.appendingPathComponent("contents")
                guard manager.fileExists(atPath: contents.path) else { continue }
                for bundle in try manager.contentsOfDirectory(at: contents, includingPropertiesForKeys: nil) where bundle.pathExtension == "wallpaper" {
                    try requireContained(bundle, in: dataURL)
                    let manifest = try readManifest(bundle.appendingPathComponent("Wallpaper.plist"))
                    let family = manifest["family"] as? String ?? "Collections"
                    let name = manifest["name"] as? String ?? "Wallpaper"
                    templates.append(WallpaperTemplate(bundleURL: bundle, versionURL: version, name: "\(family) · \(name)",
                                                       isGallery: category == "descriptors"))
                }
            }
        }
        return templates.sorted { $0.displayName < $1.displayName }
    }

    static func readManifest(_ url: URL) throws -> [String: Any] {
        guard let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any] else {
            throw OperationError(message: "This wallpaper has an unsupported manifest.")
        }
        return value
    }

    static func loadWallpapers(_ simulator: Simulator, completion: @escaping (Result<[WallpaperTemplate], Error>) -> Void) {
        queue.async {
            let result = Result { try wallpaperTemplates(in: validatedDataURL(simulator)) }
            DispatchQueue.main.async { completion(result) }
        }
    }

    static func replaceImages(_ simulator: Simulator, wallpaperID: String, imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        performOffline(simulator, completion: completion) { dataURL in
            guard let template = try wallpaperTemplates(in: dataURL).first(where: { $0.id == wallpaperID }) else {
                throw OperationError(message: "This wallpaper has changed. Refresh the list and choose it again.")
            }
            if template.isGallery {
                _ = try createWallpaper(from: template, imageURL: imageURL)
                return "A separate image wallpaper was created and selected. The original template and your other wallpapers are unchanged."
            }
            try replaceArtwork(in: template.bundleURL, imageURL: imageURL)
            try clearSnapshots(in: template.versionURL)
            return "The saved wallpaper now uses your image. Select it in the wallpaper switcher if it is not already active."
        }
    }

    static func restoreImages(_ simulator: Simulator, wallpaperID: String, completion: @escaping (Result<String, Error>) -> Void) {
        performOffline(simulator, completion: completion) { dataURL in
            guard let template = try wallpaperTemplates(in: dataURL).first(where: { $0.id == wallpaperID }) else {
                throw OperationError(message: "This wallpaper is no longer available. Refresh and try again.")
            }
            try restoreArtwork(in: template.bundleURL)
            try clearSnapshots(in: template.versionURL)
            return "The original wallpaper artwork was restored."
        }
    }

    static func reset(_ simulator: Simulator, completion: @escaping (Result<String, Error>) -> Void) {
        performOffline(simulator, completion: completion) { dataURL in
            try removeStore(in: dataURL)
            return "PosterBoard was reset. Lock Screen and StandBy layouts will be recreated."
        }
    }

    /// Refuse missing, default, or mismatched devices before any shutdown or file mutation.
    private static func validatedDataURL(_ simulator: Simulator) throws -> URL {
        guard UUID(uuidString: simulator.udid) != nil, !simulator.dataPath.isEmpty else {
            throw OperationError(message: "Select a specific simulator with a valid data folder.")
        }
        let dataURL = URL(fileURLWithPath: simulator.dataPath).standardizedFileURL
        guard dataURL.lastPathComponent == "data",
              dataURL.deletingLastPathComponent().lastPathComponent == simulator.udid else {
            throw OperationError(message: "The simulator data folder does not match its device ID.")
        }
        try checkDevice(dataURL, id: simulator.udid, requiresShutdown: false)
        return dataURL
    }

    static func checkDevice(_ dataURL: URL, id: String, requiresShutdown: Bool) throws {
        let plistURL = dataURL.deletingLastPathComponent().appendingPathComponent("device.plist")
        let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: plistURL), format: nil)
        guard let device = value as? [String: Any], device["UDID"] as? String == id,
              let runtime = device["runtime"] as? String, runtime.contains(".iOS-") else {
            throw OperationError(message: "PosterBoard controls require a matching iOS simulator.")
        }
        if requiresShutdown && device["state"] as? Int != 1 {
            throw OperationError(message: "The simulator must finish shutting down before changing PosterBoard.")
        }
    }

    private static func performOffline(_ simulator: Simulator, completion: @escaping (Result<String, Error>) -> Void, operation: @escaping (URL) throws -> String) {
        queue.async {
            let result = Result<String, Error> {
                let dataURL = try validatedDataURL(simulator)
                // Read the actual on-disk state; the sidebar refreshes only periodically.
                let plistURL = dataURL.deletingLastPathComponent().appendingPathComponent("device.plist")
                let device = try PropertyListSerialization.propertyList(from: Data(contentsOf: plistURL), format: nil) as? [String: Any]
                let state = device?["state"] as? Int
                guard state == 1 || state == 3 else {
                    throw OperationError(message: "Wait for the simulator to finish starting or stopping, then try again.")
                }
                let wasBooted = state == 3
                if wasBooted { try run(["shutdown", simulator.udid]) }
                let message: String
                do {
                    try checkDevice(dataURL, id: simulator.udid, requiresShutdown: true)
                    message = try operation(dataURL)
                } catch {
                    // Restore the device's running state even if image conversion or deletion fails.
                    if wasBooted {
                        do { try run(["boot", simulator.udid]) } catch let restartError {
                            throw OperationError(message: "\(error.localizedDescription)\nThe simulator could not restart: \(restartError.localizedDescription)")
                        }
                    }
                    throw error
                }
                if wasBooted {
                    do { try run(["boot", simulator.udid]) } catch {
                        throw OperationError(message: "\(message)\nThe change succeeded, but the simulator could not restart: \(error.localizedDescription)\nStart it manually; do not repeat the change.")
                    }
                }
                return message
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Check exit status and drain both streams; the app's older executor ignores nonzero exits.
    private static func run(_ arguments: [String]) throws {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl"] + arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let detail = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw OperationError(message: detail.isEmpty ? "simctl failed (\(process.terminationStatus))." : detail)
        }
    }

    /// Only known PosterBoard paths are removed. App data, Photos, and other preferences are preserved.
    static func removeStore(in dataURL: URL) throws {
        let manager = FileManager.default
        let springBoardURL = dataURL.appendingPathComponent("Library/Preferences/com.apple.springboard.plist")
        var resetPreferences: Data?
        if manager.fileExists(atPath: springBoardURL.path) {
            try requireContained(springBoardURL, in: dataURL)
            var preferences = try readManifest(springBoardURL)
            preferences.removeValue(forKey: "SBLockPoster")
            preferences.removeValue(forKey: "SBHomePoster")
            resetPreferences = try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
        }
        let paths = [storePath, "Library/Preferences/com.apple.PosterBoard.plist", "Library/Preferences/com.apple.PosterBoard.unprotectedUserDefaults.plist"]
        for path in paths {
            let url = dataURL.appendingPathComponent(path)
            if manager.fileExists(atPath: url.path) {
                try requireContained(url, in: dataURL)
                try manager.removeItem(at: url)
            }
        }
        if let resetPreferences { try resetPreferences.write(to: springBoardURL, options: .atomic) }
    }

    static func requireContained(_ url: URL, in root: URL) throws {
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL.path
        let canonicalRoot = root.resolvingSymlinksInPath().standardizedFileURL.path + "/"
        guard canonical.hasPrefix(canonicalRoot), canonical != String(canonicalRoot.dropLast()) else {
            throw OperationError(message: "Refusing a PosterBoard path outside the simulator data folder.")
        }
    }

}
