//
//  ControlRoomTests.swift
//  ControlRoomTests
//
//  Created by Patrick Luddy on 2/16/20.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

@testable import ControlRoom
import XCTest

class SimCtlSubCommandsTests: XCTestCase {

    func testDeleteUnavailable() throws {
        let command: SimCtl.Command = .delete(.unavailable)
        let expectation = ["simctl", "delete", "unavailable"]
        XCTAssertEqual(command.arguments, expectation)
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
