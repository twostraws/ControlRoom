//
//  Simulator.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import Cocoa
import CoreServices

typealias Runtime = SimCtl.Runtime
typealias DeviceType = SimCtl.DeviceType

/// Stores one simulator and its identifier.
struct Simulator: Identifiable, Comparable, Hashable {
    enum State {
        case unknown
        case creating
        case booting
        case booted
        case shuttingDown
        case shutdown

        init(deviceState: String?) {
            if deviceState == "Creating" {
                self = .creating
            } else if deviceState == "Booting" {
                self = .booting
            } else if deviceState == "Booted" {
                self = .booted
            } else if deviceState == "ShuttingDown" {
                self = .shuttingDown
            } else if deviceState == "Shutdown" {
                self = .shutdown
            } else {
                self = .unknown
            }
        }
    }

    /// The user-facing name for this simulator, e.g. iPhone 11 Pro Max.
    let name: String

    /// The internal identifier that represents this device.
    let udid: String

    /// Sends back the UDID for Identifiable.
    var id: String { udid }

    /// The uniform type identifier of the simulator device
    let typeIdentifier: TypeIdentifier

    /// The icon representing the simulator's device
    let image: NSImage

    /// The device family of the simulator
    var deviceFamily: SimCtl.DeviceFamily { deviceType?.family ?? .iPhone }

    /// The information about the simulator OS
    let runtime: Runtime?

    /// The device type of the simulator
    let deviceType: DeviceType?

    /// The current state of the simulator
    let state: State

    /// Wheter this simulator is the `Default` one or not
    var isDefault: Bool {
        id == "booted"
    }

    /// The path to the simulator directory location
    let dataPath: String

    init(name: String, udid: String, state: State, runtime: Runtime?, deviceType: DeviceType?, dataPath: String) {
        self.name = name
        self.udid = udid
        self.state = state
        self.runtime = runtime
        self.deviceType = deviceType
        self.dataPath = dataPath

        let typeIdentifier: TypeIdentifier

        if let model = deviceType?.modelTypeIdentifier {
            typeIdentifier = model
        } else if name.contains("iPad") {
            typeIdentifier = .defaultiPad
        } else if name.contains("Watch") {
            typeIdentifier = .defaultWatch
        } else if name.contains("TV") {
            typeIdentifier = .defaultTV
        } else {
            typeIdentifier = .defaultiPhone
        }

        self.typeIdentifier = typeIdentifier
        self.image = typeIdentifier.icon
    }

	func urlForFilePath(_ filePath: FilePathKind) -> URL {

		if filePath == .root {
			return URL(fileURLWithPath: dataPath)
		}

		let containerPath = dataPath + "/Containers/Shared/AppGroup/"

		guard let containerContents = try? FileManager.default.contentsOfDirectory(atPath: containerPath) else {
			print("could not find any subfolders in '\(containerPath)'")
			return URL(fileURLWithPath: "")
		}

		for content in containerContents {

			if content.hasSuffix("DS_Store") { continue }

			let subDirectoryPath = containerPath + content
			let plistUrl = URL(fileURLWithPath: subDirectoryPath)

			guard let subDirectoryContents = try? FileManager.default.contentsOfDirectory(atPath: subDirectoryPath),
				  let plistFile = subDirectoryContents.first(where: { $0.hasSuffix("plist")}),
				  let plistData = try? Data(contentsOf: plistUrl.appendingPathComponent(plistFile)),
				  let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? NSDictionary else {
				print("could not find or decode the plist file in '\(subDirectoryPath)'")
				return URL(fileURLWithPath: "")
			}

			for value in plist.allValues {
				if let value = value as? String {
					if value.hasSuffix(filePath.storageType) {
						return URL(fileURLWithPath: subDirectoryPath).appendingPathComponent("File Provider Storage", isDirectory: true)
					}
				}
			}
		}
		print("could not find folder of type '\(filePath)' in '\(containerPath)'")
		return URL(fileURLWithPath: "")
	}

	func copyFilesFromProviders(_ providers: [NSItemProvider], toFilePath filePath: FilePathKind) -> Bool {
		for provider in providers {
			provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
				if let urlData = urlData as? Data {
					let sourceUrl = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
					do {
						try FileManager.default.copyItem(at: sourceUrl, to: urlForFilePath(filePath).appendingPathComponent(sourceUrl.lastPathComponent))
						NSSound(named: "Glass")?.play()
					} catch {
						NSSound(named: "Sosumi")?.play()
						print(error.localizedDescription)
					}
				} else {
					NSSound(named: "Sosumi")?.play()
				}
				sleep(1)	// if multiple files are dropped, allow user to distinguish success/error sounds
			}
		}
		return true
	}

	enum FilePathKind {
		case root, files // photos is complicated, and you can't just drop files there anyway

		var storageType: String {
			switch self {
			case .root:
				print("Storage type is not applicable to the root path")
				return ""
			case .files:
				return "LocalStorage"
			}
		}
	}

    /// Sort simulators alphabetically, and then by OS version.
    static func < (lhs: Simulator, rhs: Simulator) -> Bool {
        if lhs.name == rhs.name,
           let lhsRuntime = lhs.runtime,
           let rhsRuntime = rhs.runtime {
            return lhsRuntime.buildversion < rhsRuntime.buildversion
        }
        return lhs.name < rhs.name
    }

    /// An example simulator for Xcode preview purposes
    static let example = Simulator(name: "iPhone 11 Pro max", udid: UUID().uuidString, state: .booted, runtime: .unknown, deviceType: nil, dataPath: "<example data path>")

    /// Users whichever simulator simctl feels like; if there's only one active it will be used,
    /// but if there's more than one simctl just picks one.
    static let `default` = Simulator(name: "Default", udid: "booted", state: .booted, runtime: nil, deviceType: nil, dataPath: "<default data path>")
}
