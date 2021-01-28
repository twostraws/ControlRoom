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
    let simulator: Simulator

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
                TextField("Operator", text: $preferences.carrierName, onCommit: updateData)

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
                        Image(nsImage: nsImage(named: "wifi.\(bars.rawValue)", size: NSSize(width: 19, height: 13.8)))
                            .tag(bars.rawValue)
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
                        Image(nsImage: nsImage(named: "cell.\(bars.rawValue)", size: NSSize(width: 21, height: 11.4)))
                            .tag(bars.rawValue)
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

    /// Workaround for getting configurable image sizes in Segmented Control; It seems to be broken in SwiftUI right now.
    private func nsImage(named name: String, size: NSSize) -> NSImage {
        guard let image = NSImage(named: name) else {
            return NSImage()
        }

        image.size = size
        return image
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
            return rawValue.uppercased()
        }
    }
}

extension SimCtl.StatusBar.WifiMode {
    var displayName: String {
        rawValue.capitalized
    }
}

extension SimCtl.StatusBar.CellularMode {
    var displayName: String {
        switch self {
        case .notSupported:
            return "Not Supported"
        default:
            return rawValue.capitalized
        }
    }
}
