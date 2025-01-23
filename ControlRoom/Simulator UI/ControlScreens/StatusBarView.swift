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

    /// The active data network; can be one of "WiFi", "3G", "4G", "5G", "5G+", "5G-UWB", "LTE", "LTE-A", or "LTE+".
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
                        Spacer()
                        Button("Clear overrides", action: clearOverrides)
                    }
                }

                Spacer()
                    .frame(height: 40)

                Section {
                    TextField("Operator", text: $carrierName, onCommit: updateCellularData)

                    Picker("Network type:", selection: $dataNetwork.onChange(updateWiFiData)) {
                        ForEach(SimCtl.StatusBar.DataNetwork.allCases, id: \.self) { network in
                            Text(network.displayName)
                        }
                    }
                    .pickerStyle(.menu)

                    Divider()

                    Picker("Wi-Fi mode:", selection: $wiFiMode.onChange(updateWiFiData)) {
                        ForEach(SimCtl.StatusBar.WifiMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Wi-Fi bars:", selection: $wiFiBar.onChange(updateWiFiData)) {
                        ForEach(SimCtl.StatusBar.WifiBars.allCases, id: \.self) { bars in
                            Image(systemName: "wifi", variableValue: bars.symbolVariable)
                                .tag(bars.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Divider()

                    Picker("Cellular mode:", selection: $cellularMode.onChange(updateCellularData)) {
                        ForEach(SimCtl.StatusBar.CellularMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Cellular bars:", selection: $cellularBar.onChange(updateCellularData)) {
                        ForEach(SimCtl.StatusBar.CellularBars.allCases, id: \.self) { bars in
                            Image(systemName: "cellularbars", variableValue: bars.symbolVariable)
                                .tag(bars.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()
                    .frame(height: 40)

                Section {
                    Picker("Battery state:", selection: $batteryState.onChange(updateBattery)) {
                        ForEach(SimCtl.StatusBar.BatteryState.allCases, id: \.self) { state in
                            Text(state.displayName)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    VStack(spacing: 0) {
						Text("Current battery percentage: \(Int(round(batteryLevel)))%")
							.font(.callout.monospacedDigit())

						Slider(
							value: $batteryLevel,
							in: 0...100,
							onEditingChanged: levelChanged,
							minimumValueLabel: Text("0%"),
							maximumValueLabel: Text("100%")
						) {
                            Text("Level:")
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
        .tabItem {
            Text("Status Bar")
        }
    }

    // MARK: Private methods

    /// Changes the system clock to a new value.
    private func setTime() {
        SimCtl.overrideStatusBarTime(simulator.udid, time: time)
    }

	private func setAppleTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = 9
        components.minute = 41
        components.second = 0

        let appleTime = calendar.date(from: components) ?? Date.now
        SimCtl.overrideStatusBarTime(simulator.udid, time: appleTime)

        time = appleTime
    }

    private func clearOverrides() {
        SimCtl.clearStatusBarOverrides(simulator.udid)
    }

    /// Sends status bar updates all at once; simctl gets unhappy if we send them individually, but
    /// also for whatever reason prefers cellular data sent separately from WiFi.
	private func updateWiFiData() {
		SimCtl.overrideStatusBarWiFi(
			simulator.udid,
			network: dataNetwork,
			wifiMode: wiFiMode,
			wifiBars: wiFiBar
		)
    }

    private func updateCellularData() {
		SimCtl.overrideStatusBarCellular(
			simulator.udid,
			cellMode: cellularMode,
			cellBars: cellularBar,
			carrier: carrierName
		)
    }

    /// Sends battery updates all at once; simctl gets unhappy if we send them individually.
    private func updateBattery() {
		SimCtl.overrideStatusBarBattery(
			simulator.udid,
			level: Int(batteryLevel),
			state: batteryState
		)
    }

    /// Triggered when the user adjusts the battery level.
    private func levelChanged(_ isEditing: Bool) {
        if isEditing == false {
            updateBattery()
        }
    }
}

// MARK: Preview

struct StatusBarViewView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarView(simulator: .example)
            .environmentObject(Preferences())
    }
}

// MARK: Extensions

extension SimCtl.StatusBar.DataNetwork {
    var displayName: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
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
