//
//  NetworkView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Controls WiFi and cellular data state for the whole device.
struct NetworkView: View {
    var simulator: Simulator

    /// The active data network; can be one of "WiFi", "3G", "4G", "LTE", "LTE-A", or "LTE+".
    @State private var dataNetwork = "WiFi"

    /// Whether WiFi is currently active; can be "Active", "Searching", or "Failed".
    @State private var wiFiMode = "Active"

    /// How many WiFi bars the device is showing, as a range from 0 through 3.
    @State private var wiFiBar = "3"

    /// Whether cellular data is currently active; can be "Active", "Searching", "Failed", or "Not Supported".
    @State private var cellularMode = "Active"

    /// How many cellular bars the device is showing, as a range from 0 through 4.
    @State private var cellularBar = "4"

    /// The cell carrier name to display.
    @State private var operatorName = UserDefaults.standard.string(forKey: Defaults.operatorName) ?? "Carrier"

    /// All possible data network options.
    private let dataNetworks = ["WiFi", "3G", "4G", "LTE", "LTE-A", "LTE+"]

    /// All possible WiFi modes.
    private let wiFiModes = ["Active", "Searching", "Failed"]

    /// The full range of WiFi bars we can control.
    private let wiFiBars = (0...3).map(String.init)

    /// All possible cellular modes.
    private let cellularModes = ["Active", "Searching", "Failed", "Not Supported"]

    /// The full range of cellular bars we can show.
    private let cellularBars = (0...4).map(String.init)

    /// Converts the user-facing cellular mode to one that can be read by simctl.
    var cleanedCellularMode: String {
        if cellularMode == "Not Supported" {
            return "notSupported"
        } else {
            return cellularMode.lowercased()
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("Operator", text: $operatorName) {
                    UserDefaults.standard.set(self.operatorName, forKey: Defaults.operatorName)
                    self.updateData()
                }

                Picker("Network type:", selection: $dataNetwork.onChange(updateData)) {
                    ForEach(dataNetworks, id: \.self) { network in
                        Text(network)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
            }

            FormSpacer()

            Section {
                Picker("WiFi mode:", selection: $wiFiMode.onChange(updateData)) {
                    ForEach(wiFiModes, id: \.self) { mode in
                        Text(mode)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())

                Picker("WiFi bars:", selection: $wiFiBar.onChange(updateData)) {
                    ForEach(0..<wiFiBars.count) { idx in
                        Image("wifi\(idx)")
                            .resizable()
                            .tag(self.wiFiBars[idx])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            FormSpacer()

            Section {
                Picker("Cellular mode:", selection: $cellularMode.onChange(updateData)) {
                    ForEach(cellularModes, id: \.self) { mode in
                        Text(mode)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())

                Picker("Cellular bars:", selection: $cellularBar.onChange(updateData)) {
                    ForEach(0 ..< cellularBars.count) { idx in
                    Image("cell\(idx)")
                        .resizable()
                        .tag(self.cellularBars[idx])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Spacer()
        }
        .tabItem {
            Text("Network")
        }
        .padding()
    }

    /// Sends status bar updates all at once; simctl gets unhappy if we send them individually.
    func updateData() {
        Command.simctl("status_bar", self.simulator.udid, "override",
                       "--dataNetwork", dataNetwork.lowercased(),
                       "--wifiMode", wiFiMode.lowercased(),
                       "--wifiBars", wiFiBar,
                       "--cellularMode", cleanedCellularMode,
                       "--cellularBars", cellularBar,
                       "--operatorName", operatorName)
    }
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView(simulator: .example)
    }
}
