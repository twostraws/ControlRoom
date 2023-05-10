//
//  ControlRoomTests.swift
//  ControlRoomTests
//
//  Created by Patrick Luddy on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

@testable import Control_Room
import XCTest

class SimCtlSubCommandsTests: XCTestCase {

    func testDeleteUnavailable() throws {
        let command: SimCtl.Command = .delete(.unavailable)
        let expectation = ["simctl", "delete", "unavailable"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testBoot() throws {
        let getSimulator: (String) -> Simulator = { buildVersion in
            let runtime = Runtime(buildversion: buildVersion, identifier: "made-up", version: "version", isAvailable: true, name: "iPhone 14")
            return Simulator(name: "iPhone 14", udid: "made-up-udid", state: .shutdown, runtime: runtime, deviceType: nil, dataPath: "fake-path")
        }
        let expectedArguments = ["simctl", "boot", "made-up-udid"]

        let command160: SimCtl.Command = .boot(simulator: getSimulator("16.0"))
        XCTAssertEqual(command160.arguments, expectedArguments)
        XCTAssertEqual(command160.environmentOverrides, nil)

        let command161: SimCtl.Command = .boot(simulator: getSimulator("16.1"))
        XCTAssertEqual(command161.arguments, expectedArguments)
        XCTAssertEqual(command161.environmentOverrides, ["SIMCTL_CHILD_SIMULATOR_RUNTIME_VERSION": "16.0"])
    }

    func testRecordAVideo() throws {
        let command: SimCtl.Command = .io(deviceId: "device1", operation: .recordVideo(codec: .h264, url: "~/my-video.mov"))
        let expectation = ["simctl", "io", "device1", "recordVideo", "--codec=h264", "~/my-video.mov"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testScreenshot() throws {
        let command: SimCtl.Command = .io(deviceId: "device1", operation: .screenshot(type: .png, display: .internal, mask: .ignored, url: "~/my-image.png"))
        let expectation = ["simctl", "io", "device1", "screenshot", "--type=png", "--display=internal", "--mask=ignored", "~/my-image.png"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testlist() throws {
        let command: SimCtl.Command = .list()
        let expectation = ["simctl", "list"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testlistFilterSearchFlag() throws {
        let command: SimCtl.Command = .list(filter: .devicetypes, search: .string("search"), flags: [.json])
        let expectation = ["simctl", "list", "devicetypes", "search", "-j"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testOpenUrl() throws {
        let command: SimCtl.Command = .openURL(deviceId: "device1", url: "https://www.hackingwithswift.com")
        let expectation = ["simctl", "openurl", "device1", "https://www.hackingwithswift.com"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testAddMedia() throws {
        let command: SimCtl.Command = .addMedia(deviceId: "device1", mediaPaths: ["~/sample-1.jpg"])
        let expectation = ["simctl", "addmedia", "device1", "~/sample-1.jpg"]
        XCTAssertEqual(command.arguments, expectation)
    }

    func testDefaultsForApp() throws {
        let command: SimCtl.Command = .spawn(deviceId: "device1", pathToExecutable: "defaults read", options: [.waitForDebugger])
        let expectation = ["simctl", "spawn", "-w", "device1", "defaults read"]
        XCTAssertEqual(command.arguments, expectation)
    }
}
