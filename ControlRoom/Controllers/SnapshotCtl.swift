//
//  SnapshotCtl.swift
//  ControlRoom
//
//  Created by Marcel Mendes on 12/12/24.
//  Copyright © 2024 Paul Hudson. All rights reserved.
//

import Foundation
import Combine

enum SnapshotCtl: CommandLineCommandExecuter {
    typealias Error = CommandLineError
    
    static var launchPath = ""
    static var snapshotsPath = ""
    static var devicesPath = "" {
        didSet {
            snapshotsPath = devicesPath + "/.snapshots"
        }
    }
    
    static func configureDevicesPath(dataPath: String?) {
        guard let dataPath else {
            print("Missing dataPath. Snapshots won't be created.")
            return
        }
        
        var folders: [String] = []
        
        dataPath.split(separator: "/").forEach {
            folders.append("\($0)")
        }
        
        if let devicesIndex: Int = folders.firstIndex(of: "Devices") {
            devicesPath = "/" + folders.prefix(devicesIndex + 1).joined(separator: "/")
        }
    }

    static func getSnapshots(deviceId: String) -> [Snapshot] {
        let snapshotsPath: String = devicesPath + "/.snapshots/" + deviceId
        var snapshotIDs: [String] = []
        var snapshots: [Snapshot] = []
        
        do {
            snapshotIDs = try FileManager.default.contentsOfDirectory(atPath: snapshotsPath)
        } catch { }
        
        snapshotIDs.forEach { snapshotID in
            guard !snapshotID.hasPrefix(".") else { return }

            let snapshotPath: String = snapshotsPath + "/" + snapshotID
            let snapshotAttributes = getSnapshotAttributes(snapshotPath)

            guard let creationDate = snapshotAttributes.creationDate,
                  let snapshotFolderSize = snapshotAttributes.folderSize else { return }
            let snapshot: Snapshot = .init(id: snapshotID, creationDate: creationDate, size: snapshotFolderSize)
            snapshots.append(snapshot)
        }
        
        return snapshots
    }
    
    static func createSnapshot(deviceId: String, snapshotName: String) {
        SimCtl.shutdown(deviceId) { _ in
            execute(.createSnapshotTree(deviceId: deviceId, snapshotName: snapshotName)) { _ in
                try? FileManager.default.copyItem(atPath: devicesPath + "/" + deviceId, toPath: snapshotsPath + "/" + deviceId + "/" + snapshotName + "/" + deviceId)
            }
        }
    }
    
    static func renameSnapshot(deviceId: String, snapshotName: String, newSnapshotName: String) {
        let snapshotPath: String = snapshotsPath + "/" + deviceId
        try? FileManager.default.moveItem(atPath: snapshotPath + "/" + snapshotName, toPath: snapshotPath + "/" + newSnapshotName)
    }
    
    static func deleteSnapshot(deviceId: String, snapshotName: String) {
        let snapshotPath: String = snapshotsPath + "/" + deviceId
        try? FileManager.default.removeItem(atPath: snapshotPath + "/" + snapshotName)
    }
    
    static func deleteAllSnapshots(deviceId: String) {
        let snapshotPath: String = snapshotsPath + "/" + deviceId
        try? FileManager.default.removeItem(atPath: snapshotPath)
    }
    
    static func restoreSnapshot(deviceId: String, snapshotName: String) {
        let snapshotPath: String = snapshotsPath + "/" + deviceId

        SimCtl.shutdown(deviceId) { _ in
            try? FileManager.default.removeItem(atPath: devicesPath + "/" + deviceId)
            try? FileManager.default.copyItem(atPath: snapshotPath + "/" + snapshotName + "/" + deviceId, toPath: devicesPath + "/" + deviceId)
        }
    }
    
    static func startSimulatorApp(completion: @escaping (() -> Void)) {
        execute(.open(app: "Simulator.app")) { _ in
            return completion()
        }
    }

    private static func getSnapshotAttributes(_ snapshotPath: String) -> URLFileAttribute {
        let snapshotURL: URL = URL(fileURLWithPath: snapshotPath)
        let snapshotAttributes = URLFileAttribute(url: snapshotURL)
        return snapshotAttributes
    }
    
}
