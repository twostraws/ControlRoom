//
//  StatusBarView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Controls WiFi and cellular data state for the whole device.
struct StatusBarView: View {
    let simulator: Simulator

    /// The current time to show in the device.
    @State private var time = Date.now

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

    @AppStorage("CRNetwork_CarrierName") private var carrierName = "Carrier"


    /// The current battery level of the device, as a value from 0 through 100
    @State private var batteryLevel = 100.0

    /// The current battery state of the device; must be "Charging", "Charged", or "Discharging"
    /// Note: "Charged" looks the same as "Discharging", so it's not included in this screen.
    @State private var batteryState: SimCtl.StatusBar.BatteryState = .charging

    

    var body: some View {
        ScrollView {
            Form {
                Section {
                    HStack {
                        DatePicker("Time:", selection: $time)
                        Button("Set", action: setTime)
                        Button("Set to 9:41", action: setAppleTime)
                    }
                }
                
                Divider()
                    .padding(.vertical, 20)
                
                Section {
                    TextField("Operator", text: $carrierName, onCommit: updateNetworkData)
                    
                    Picker("Network type:", selection: $dataNetwork.onChange(updateNetworkData)) {
                        ForEach(SimCtl.StatusBar.DataNetwork.allCases, id: \.self) { network in
                            Text(network.displayName)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    
                    Divider()
                    
                    Picker("WiFi mode:", selection: $wiFiMode.onChange(updateNetworkData)) {
                        ForEach(SimCtl.StatusBar.WifiMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    
                    Picker("WiFi bars:", selection: $wiFiBar.onChange(updateNetworkData)) {
                        ForEach(SimCtl.StatusBar.WifiBars.allCases, id: \.self) { bars in
                            Image(systemName: "wifi", variableValue: bars.rawValue)
                            //                            .frame
                                .tag(bars.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Divider()
                    
                    Picker("Cellular mode:", selection: $cellularMode.onChange(updateNetworkData)) {
                        ForEach(SimCtl.StatusBar.CellularMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    
                    Picker("Cellular bars:", selection: $cellularBar.onChange(updateNetworkData)) {
                        ForEach(SimCtl.StatusBar.CellularBars.allCases, id: \.self) { bars in
                            Image(systemName: "cellularbars", variableValue: bars.rawValue)
                                .tag(bars.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                }
                
                Divider()
                    .padding(.vertical, 20)
                
                Section {
                    Picker("Battery State:", selection: $batteryState.onChange(updateBattery)) {
                        ForEach(SimCtl.StatusBar.BatteryState.allCases, id: \.self) { state in
                            Text(state.displayName)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    
                    VStack {
                        Text("Current battery percentage: \(Int(round(batteryLevel)))%")
                        Slider(value: $batteryLevel, in: 0...100, onEditingChanged: levelChanged, minimumValueLabel: Text("0%"), maximumValueLabel: Text("100%")) {
                            Text("Level:")
                        }
                    }
                }
            }
            .padding()
        }
        .tabItem {
            Text("Status Bar")
        }
    }

    /// Changes the system clock to a new value.
    func setTime() {
        SimCtl.overrideStatusBarTime(simulator.udid, time: time)
    }

    func setAppleTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = 9
        components.minute = 41
        components.second = 0

        let appleTime = calendar.date(from: components) ?? Date.now
        SimCtl.overrideStatusBarTime(simulator.udid, time: appleTime)

        time = appleTime
    }

    /// Sends status bar updates all at once; simctl gets unhappy if we send them individually.
    func updateNetworkData() {
        SimCtl.overrideStatusBarNetwork(simulator.udid, network: dataNetwork,
                                        wifiMode: wiFiMode, wifiBars: wiFiBar,
                                        cellMode: cellularMode, cellBars: cellularBar,
                                        carrier: carrierName)
    }

    /// Sends battery updates all at once; simctl gets unhappy if we send them individually.
    func updateBattery() {
        SimCtl.overrideStatusBarBattery(simulator.udid, level: Int(batteryLevel), state: batteryState)
    }

    /// Triggered when the user adjusts the battery level.
    func levelChanged(_ isEditing: Bool) {
        if isEditing == false {
            updateBattery()
        }
    }
}

struct StatusBarViewView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarView(simulator: .example)
            .environmentObject(Preferences())
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
