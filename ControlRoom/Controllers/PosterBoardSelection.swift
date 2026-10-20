import Foundation
import SQLite3

extension PosterBoardController {
    private static func useLockWallpaperForHome(at url: URL) throws {
        guard var archive = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any],
              var objects = archive["$objects"] as? [Any], let top = archive["$top"] as? [String: Any] else {
            throw OperationError(message: "Unsupported Home Screen presentation settings.")
        }
        let index = try archiveIndex(top["root"])
        guard objects.indices.contains(index), var configuration = objects[index] as? [String: Any],
              try selfObjectClass(configuration, objects: objects) == "PRPosterHomeScreenConfiguration" else {
            throw OperationError(message: "Unsupported Home Screen configuration archive.")
        }
        configuration["selectedAppearanceType"] = 0
        objects[index] = configuration
        archive["$objects"] = objects
        try PropertyListSerialization.data(fromPropertyList: archive, format: .binary, options: 0).write(to: url, options: .atomic)
    }

    /// Resolve keyed-archive references by their public XML plist representation;
    /// never assume object-array indices from one user's SpringBoard preferences.
    private static func archiveIndex(_ reference: Any?) throws -> Int {
        guard let reference else { throw OperationError(message: "Missing poster archive reference.") }
        let data = try PropertyListSerialization.data(fromPropertyList: ["reference": reference], format: .xml, options: 0)
        let xml = String(decoding: data, as: UTF8.self)
        guard xml.contains("<key>CF$UID</key>"), let start = xml.range(of: "<integer>"),
              let end = xml.range(of: "</integer>", range: start.upperBound..<xml.endIndex),
              let index = Int(xml[start.upperBound..<end.lowerBound]) else {
            throw OperationError(message: "Unsupported poster archive reference.")
        }
        return index
    }

    // The archive traversal stays together so all identity fields are updated coherently.
    // swiftlint:disable:next function_body_length
    static func selectingPoster(in preferencesData: Data, identifier: UUID, descriptor: String, version: Int, contentsURL: URL) throws -> Data {
        guard var preferences = try PropertyListSerialization.propertyList(from: preferencesData, format: nil) as? [String: Any],
              let archiveData = preferences["SBLockPoster"] as? Data,
              var archive = try PropertyListSerialization.propertyList(from: archiveData, format: nil) as? [String: Any],
              var objects = archive["$objects"] as? [Any], let top = archive["$top"] as? [String: Any] else {
            throw OperationError(message: "Set up a Lock Screen wallpaper first; its saved poster identity is unavailable.")
        }
        func object(_ reference: Any?) throws -> [String: Any] {
            let index = try archiveIndex(reference)
            guard objects.indices.contains(index), let object = objects[index] as? [String: Any] else {
                throw OperationError(message: "Unsupported poster archive object.")
            }
            return object
        }
        func className(_ object: [String: Any]) throws -> String? { try selfObjectClass(object, objects: objects) }
        let root = try object(top["root"])
        guard try className(root) == "PRSPosterConfiguration" else {
            throw OperationError(message: "This runtime uses an unsupported poster selection archive.")
        }
        let pathIndex = try archiveIndex(root["p"])
        let path = try object(root["p"])
        let identityIndex = try archiveIndex(path["i"])
        var identity = try object(path["i"])
        guard try className(path) == "PFServerPosterPath", try className(identity) == "PFServerPosterIdentity",
              identity["t"] as? Int == 3 else {
            throw OperationError(message: "The saved wallpaper identity is not a supported configuration path.")
        }
        let roleIndex = try archiveIndex(identity["r"])
        guard objects.indices.contains(roleIndex), objects[roleIndex] as? String == "PRPosterRoleLockScreen" else {
            throw OperationError(message: "The saved poster does not identify a Lock Screen wallpaper.")
        }
        func replaceReferencedString(_ reference: Any?, with value: String) throws {
            let index = try archiveIndex(reference)
            guard objects.indices.contains(index), objects[index] is String else { throw OperationError(message: "Unsupported poster string reference.") }
            objects[index] = value
        }
        try replaceReferencedString(identity["p"], with: "com.apple.WallpaperKit.CollectionsPoster")
        try replaceReferencedString(identity["d"], with: descriptor)
        let uuidIndex = try archiveIndex(identity["u"])
        var uuidObject = try object(identity["u"])
        guard try className(uuidObject) == "NSUUID" else { throw OperationError(message: "Unsupported poster UUID encoding.") }
        var bytes = identifier.uuid
        uuidObject["NS.uuidbytes"] = withUnsafeBytes(of: &bytes) { Data($0) }
        objects[uuidIndex] = uuidObject
        identity["v"] = version
        identity["s"] = 0
        objects[identityIndex] = identity
        let urlIndex = try archiveIndex(path["c"])
        let url = try object(path["c"])
        guard try className(url) == "NSURL" else { throw OperationError(message: "Unsupported poster contents URL.") }
        try replaceReferencedString(url["NS.relative"], with: contentsURL.absoluteString)
        // Preserve URL/base, display pin, role, class hierarchy and unknown archive fields.
        objects[urlIndex] = url
        objects[pathIndex] = path
        archive["$objects"] = objects
        preferences["SBLockPoster"] = try PropertyListSerialization.data(fromPropertyList: archive, format: .binary, options: 0)
        return try PropertyListSerialization.data(fromPropertyList: preferences, format: .binary, options: 0)
    }

    private static func selfObjectClass(_ object: [String: Any], objects: [Any]) throws -> String? {
        let index = try archiveIndex(object["$class"])
        guard objects.indices.contains(index) else { throw OperationError(message: "Invalid poster archive class reference.") }
        return (objects[index] as? [String: Any])?["$classname"] as? String
    }

    // A gallery preset can be hidden by a runtime's gallery policy. Materialize it as a
    // separate saved wallpaper instead of modifying the preset or relying on that policy.
    // Keep file staging, selection and transaction rollback in one scope.
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    static func createWallpaper(from template: WallpaperTemplate, imageURL: URL) throws -> String {
        let manager = FileManager.default
        let posterRoot = template.versionURL.deletingLastPathComponent().deletingLastPathComponent()
        let providerRoot = posterRoot.deletingLastPathComponent().deletingLastPathComponent()
        let structure = providerRoot.deletingLastPathComponent().deletingLastPathComponent()
        guard template.isGallery, posterRoot.deletingLastPathComponent().lastPathComponent == "descriptors",
              providerRoot.lastPathComponent == "com.apple.WallpaperKit.CollectionsPoster" else {
            throw OperationError(message: "Select a Collections gallery template to create an image wallpaper.")
        }
        let identifier = UUID().uuidString
        let newRoot = providerRoot.appendingPathComponent("configurations/\(identifier)")
        try requireContained(providerRoot, in: structure)
        try manager.createDirectory(at: newRoot.appendingPathComponent("versions"), withIntermediateDirectories: true)
        do {
            for name in ["providerInfo.plist", "com.apple.posterkit.role.identifier", "com.apple.posterkit.provider.descriptor.identifier"] {
                let source = posterRoot.appendingPathComponent(name)
                try requireContained(source, in: structure)
                try manager.copyItem(at: source, to: newRoot.appendingPathComponent(name))
            }
            let role = try String(contentsOf: newRoot.appendingPathComponent("com.apple.posterkit.role.identifier"), encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard role == "PRPosterRoleLockScreen" else { throw OperationError(message: "This template is not a Lock Screen wallpaper.") }
            let version = newRoot.appendingPathComponent("versions/0")
            try manager.createDirectory(at: version, withIntermediateDirectories: true)
            // Copy authored provider content, never scratch or rendered snapshot caches.
            for item in try manager.contentsOfDirectory(at: template.versionURL, includingPropertiesForKeys: nil) {
                guard !item.lastPathComponent.hasPrefix("RuntimeSnapshot"), !["scratch", "FallbackSnapshots"].contains(item.lastPathComponent) else { continue }
                try requireContained(item, in: structure)
                try manager.copyItem(at: item, to: version.appendingPathComponent(item.lastPathComponent))
            }
            let database = try PosterDatabase(url: structure.appendingPathComponent("PBFPosterExtensionDataStoreSQLiteDatabase.sqlite3"))
            let presentation = try database.presentationVersion(in: structure)
            for item in try manager.contentsOfDirectory(at: presentation, includingPropertiesForKeys: nil) {
                guard item.lastPathComponent.hasPrefix("com.apple.posterkit.provider.instance.") || item.lastPathComponent == "supplements" else { continue }
                try requireContained(item, in: structure)
                let destination = version.appendingPathComponent(item.lastPathComponent)
                if manager.fileExists(atPath: destination.path) { try manager.removeItem(at: destination) }
                try manager.copyItem(at: item, to: destination)
            }
            let homeURL = version.appendingPathComponent("supplements/0/com.apple.posterkit.provider.supplementURL.homescreenConfiguration.plist")
            try useLockWallpaperForHome(at: homeURL)
            let bundle = version.appendingPathComponent("contents/\(template.bundleURL.lastPathComponent)")
            try replaceArtwork(in: bundle, imageURL: imageURL)
            let dataURL = structure.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            try checkDevice(dataURL, id: dataURL.deletingLastPathComponent().lastPathComponent, requiresShutdown: true)
            let preferencesURL = dataURL.appendingPathComponent("Library/Preferences/com.apple.springboard.plist")
            let oldPreferences = try Data(contentsOf: preferencesURL)
            let descriptor = try String(contentsOf: newRoot.appendingPathComponent("com.apple.posterkit.provider.descriptor.identifier"), encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let uuid = UUID(uuidString: identifier), !descriptor.isEmpty else { throw OperationError(message: "The template descriptor identity is missing.") }
            let newPreferences = try selectingPoster(in: oldPreferences, identifier: uuid, descriptor: descriptor, version: 0,
                                                     contentsURL: version.appendingPathComponent("contents", isDirectory: true))
            try database.execute("BEGIN IMMEDIATE")
            do {
                try database.execute("INSERT INTO poster (UUID, providerId) VALUES (?, ?)", [identifier, providerRoot.lastPathComponent])
                try database.execute("INSERT INTO posterRoleMembership (posterUUID, roleId, roleSortKey) SELECT ?, ?, COALESCE(MAX(roleSortKey), 0)+1 FROM posterRoleMembership WHERE roleId = ?", [identifier, role, role])
                try database.execute("UPDATE posterAttributes SET attributePayload = '0' WHERE roleId = ? AND attributeIdentifier = 'SELECTED'", [role])
                try database.execute("INSERT INTO posterAttributes (posterUUID, roleId, attributeIdentifier, attributePayload) VALUES (?, ?, 'SELECTED', '1')", [identifier, role])
                let now = Date().timeIntervalSince1970
                let metadata: [String: Any] = ["attributeType": "PRPosterRoleAttributeTypeUsageMetadata", "creationDate": now,
                                                "lastModifiedDate": now, "lastActivatedDate": now, "extensionAvailable": true]
                let payload = String(decoding: try JSONSerialization.data(withJSONObject: metadata), as: UTF8.self)
                try database.execute("INSERT INTO posterAttributes (posterUUID, roleId, attributeIdentifier, attributePayload) VALUES (?, ?, 'PRPosterRoleAttributeTypeUsageMetadata', ?)", [identifier, role, payload])
                try newPreferences.write(to: preferencesURL, options: .atomic)
                try database.execute("COMMIT")
            } catch {
                try? database.execute("ROLLBACK")
                do { try oldPreferences.write(to: preferencesURL, options: .atomic) } catch let restoreError {
                    throw OperationError(message: "Poster selection could not be restored: \(restoreError.localizedDescription)")
                }
                throw error
            }
        } catch {
            try? manager.removeItem(at: newRoot)
            throw error
        }
        return identifier
    }

}

/// Unsupported schemas fail before commit; a missing database is never created.
private final class PosterDatabase {
    private let handle: OpaquePointer

    init(url: URL) throws {
        var database: OpaquePointer?
        let result = sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)
        guard result == SQLITE_OK, let database else {
            let detail = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Could not open PosterBoard database."
            if let database { sqlite3_close(database) }
            throw PosterBoardController.OperationError(message: detail)
        }
        handle = database
        sqlite3_busy_timeout(handle, 3000)
        do {
            try execute("PRAGMA foreign_keys = ON")
        } catch {
            sqlite3_close(handle)
            throw error
        }
    }

    deinit { sqlite3_close(handle) }

    func presentationVersion(in structure: URL) throws -> URL {
        let sql = """
        SELECT p.UUID, p.providerId
        FROM poster p
        JOIN posterRoleMembership r ON p.UUID = r.posterUUID
        LEFT JOIN posterAttributes a ON p.UUID = a.posterUUID AND a.roleId = r.roleId AND a.attributeIdentifier = 'SELECTED'
        WHERE r.roleId = 'PRPosterRoleLockScreen'
        ORDER BY (a.attributePayload = '1') DESC, p.posterId DESC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw PosterBoardController.OperationError(message: "Could not read the existing wallpaper presentation settings.")
        }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let uuidText = sqlite3_column_text(statement, 0), let providerText = sqlite3_column_text(statement, 1) else { continue }
            let identifier = String(cString: uuidText)
            let provider = String(cString: providerText)
            guard UUID(uuidString: identifier) != nil, provider.hasPrefix("com.apple."), !provider.contains("/") else { continue }
            let versions = structure.appendingPathComponent("Extensions/\(provider)/configurations/\(identifier)/versions")
            let candidates = (try? FileManager.default.contentsOfDirectory(at: versions, includingPropertiesForKeys: nil)) ?? []
            for version in candidates.filter({ Int($0.lastPathComponent) != nil }).sorted(by: {
                (Int($0.lastPathComponent) ?? 0) > (Int($1.lastPathComponent) ?? 0)
            }) {
                let home = version.appendingPathComponent("supplements/0/com.apple.posterkit.provider.supplementURL.homescreenConfiguration.plist")
                if FileManager.default.fileExists(atPath: home.path) { return version }
            }
        }
        throw PosterBoardController.OperationError(message: "Set up a wallpaper on this simulator first so its display and clock settings are available.")
    }

    func execute(_ sql: String, _ values: [String] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw PosterBoardController.OperationError(message: "Unsupported PosterBoard database: \(String(cString: sqlite3_errmsg(handle)))")
        }
        defer { sqlite3_finalize(statement) }
        for (index, value) in values.enumerated() {
            let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            guard sqlite3_bind_text(statement, Int32(index + 1), value, -1, transient) == SQLITE_OK else {
                throw PosterBoardController.OperationError(message: "Could not bind PosterBoard database values.")
            }
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw PosterBoardController.OperationError(message: "PosterBoard database update failed: \(String(cString: sqlite3_errmsg(handle)))")
        }
    }
}
