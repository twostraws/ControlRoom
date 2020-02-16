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
    @EnvironmentObject var preferences: Preferences
    var simulator: Simulator

    /// The active data network; can be one of "WiFi", "3G", "4G", "LTE", "LTE-A", or "LTE+".
    @State private var dataNetwork: SimCtl.StatusBar.DataNetwork = .wifi

    /// Whether WiFi is currently active; can be "Active", "Searching", or "Failed".
    @State private var wiFiMode: SimCtl.StatusBar.WifiMode = .active

    /// How many WiFi bars the device is showing, as a range from 0 through 3.
    @State private var wiFiBar: SimCtl.StatusBar.WifiBars = .three

    /// Whether cellular data is currently active; can be "Active", "Searching", "Failed", or "Not Supported".
    @State private var cellularMode: SimCtl.StatusBar.CellularMode = .active

    /// How many cellular bars the device is showing, as a range from 0 through 4.
    @State private var cellularBar: SimCtl.StatusBar.CellularBars = .four

    var body: some View {
        Form {
            Section {
                TextField("Operator", text: $preferences.carrierName) {
                    self.updateData()
                }

                Picker("Network type:", selection: $dataNetwork.onChange(updateData)) {
                    ForEach(SimCtl.StatusBar.DataNetwork.allCases, id: \.self) { network in
                        Text(network.displayName)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
            }

            FormSpacer()

            Section {
                Picker("WiFi mode:", selection: $wiFiMode.onChange(updateData)) {
                    ForEach(SimCtl.StatusBar.WifiMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())

                Picker("WiFi bars:", selection: $wiFiBar.onChange(updateData)) {
                    ForEach(SimCtl.StatusBar.WifiBars.allCases, id: \.self) { bars in
                        Image("wifi\(bars.rawValue)")
                            .resizable()
                            .tag(bars)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            FormSpacer()

            Section {
                Picker("Cellular mode:", selection: $cellularMode.onChange(updateData)) {
                    ForEach(SimCtl.StatusBar.CellularMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())

                Picker("Cellular bars:", selection: $cellularBar.onChange(updateData)) {
                    ForEach(SimCtl.StatusBar.CellularBars.allCases, id: \.self) { bars in
                        Image("cell\(bars.rawValue)")
                        .resizable()
                        .tag(bars)
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
        SimCtl.overrideStatusBarNetwork(simulator.udid, network: dataNetwork,
                                        wifiMode: wiFiMode, wifiBars: wiFiBar,
                                        cellMode: cellularMode, cellBars: cellularBar,
                                        carrier: preferences.carrierName)
    }
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView(simulator: .example)
    }
}

extension SimCtl.StatusBar.DataNetwork {
    var displayName: String {
        switch self {
        case .wifi:
            return "WiFi"
        default:
            return self.rawValue.uppercased()
        }
    }
}

extension SimCtl.StatusBar.WifiMode {
    var displayName: String {
        self.rawValue.capitalized
    }
}

extension SimCtl.StatusBar.CellularMode {
    var displayName: String {
        switch self {
        case .notSupported:
            return "Not Supported"
        default:
            return self.rawValue.capitalized
        }
    }
}
