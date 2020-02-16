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
        let subcommand = SimCtl.SubCommand.delete(.unavailable)
        let expectation = ["delete", "unavailable"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testRecordAVideo() throws {
        let subcommand = SimCtl.SubCommand.io(deviceId: "device1", operation: .recordVideo(codec: .h264, url: "~/my-video.mov"))
        let expectation = ["io", "device1", "recordVideo", "--codec=h264", "~/my-video.mov"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testScreenshot() throws {
        let subcommand = SimCtl.SubCommand.io(deviceId: "device1", operation: .screenshot(type: .png, display: .internal, mask: .ignored, url: "~/my-image.png"))
        let expectation = ["io", "device1", "screenshot", "--type=png", "--display=internal", "--mask=ignored", "~/my-image.png"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testlist() throws {
        let subcommand = SimCtl.SubCommand.list()
        let expectation = ["list"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testlistFilterSearchFlag() throws {
        let subcommand = SimCtl.SubCommand.list(filter: .devicetypes, search: .string("search"), flags: [.json])
        let expectation = ["list", "devicetypes", "search", "-j"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testOpenUrl() throws {
        let subcommand = SimCtl.SubCommand.openurl(deviceId: "device1", url: "https://www.hackingwithswift.com")
        let expectation = ["openurl", "device1", "https://www.hackingwithswift.com"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testAddMedia() throws {
        let subcommand = SimCtl.SubCommand.addmedia(deviceId: "device1", mediaPaths: ["~/sample-1.jpg"])
        let expectation = ["addmedia", "device1", "~/sample-1.jpg"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }

    func testDefaultsForApp() throws {
        let subcommand = SimCtl.SubCommand.spawn(deviceId: "device1", pathToExecutable: "defaults read", options: [.waitForDebugger])
        let expectation = ["spawn", "-w", "device1", "defaults read"]
        XCTAssertEqual(subcommand.arguments, expectation)
    }
}
