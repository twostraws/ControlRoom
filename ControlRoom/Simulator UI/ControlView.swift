//
//  ControlView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// The main tab view to control simulator settings.
struct ControlView: View {
    /// Used to handle creating screenshots, videos, and GIFs.
    @StateObject private var captureController = CaptureController()

    /// Let's us watch the list of active simulators.
    @ObservedObject var controller: SimulatorsController

    let simulator: Simulator
    let applications: [Application]

    var body: some View {
        TabView {
            SystemView(simulator: simulator, controller: controller)
                .disabled(simulator.state != .booted)
            SnapshotsView(simulator: simulator, controller: controller)
            Group {
                AppView(simulator: simulator, applications: applications)
                LocationView(controller: controller, simulator: simulator)
                StatusBarView(simulator: simulator)
                OverridesView(simulator: simulator)
                ColorsView()
            }
            .disabled(simulator.state != .booted)

        }
        .navigationSubtitle("\(simulator.name) – \(simulator.runtime?.name ?? "Unknown OS")")
        .toolbar {
            Menu("Save \(captureController.imageFormatString)") {
                Button("Save as PNG") {
                    captureController.takeScreenshot(of: simulator, format: .png)
                }

                Button("Save as JPEG") {
                    captureController.takeScreenshot(of: simulator, format: .jpeg)
                }

                Button("Save as TIFF") {
                    captureController.takeScreenshot(of: simulator, format: .tiff)
                }

                Button("Save as BMP") {
                    captureController.takeScreenshot(of: simulator, format: .bmp)
                }
            } primaryAction: {
                captureController.takeScreenshot(of: simulator)
            }

            if captureController.recordingProcess == nil {
                Menu("Record \(captureController.videoFormatString)") {
                    ForEach(SimCtl.IO.VideoFormat.all, id: \.self) { item in
                        if item == .divider {
                            Divider()
                        } else {
                            Button("Save as \(item.name)") {
                                captureController.startRecordingVideo(of: simulator, format: item)
                            }
                        }
                    }
                } primaryAction: {
                    captureController.startRecordingVideo(of: simulator)
                }
            } else {
                Button("Stop Recording", action: captureController.stopRecordingVideo)
            }

            if simulator.state != .booted {
                Button("Boot", action: bootDevice)
            }

            if simulator.state != .shutdown {
                Button("Shutdown", action: shutdownDevice)
            }
        }
    }

    /// Launches the current device.
    func bootDevice() {
        SimCtl.boot(simulator)
    }

    /// Terminates the current device.
    func shutdownDevice() {
        SimCtl.shutdown(simulator.udid)
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(controller: .init(preferences: .init()),
                    simulator: .example,
                    applications: [])
            .environmentObject(Preferences())
    }
}
