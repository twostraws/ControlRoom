//
//  StatusBarView.swift
//  ControlRoom
//
//  Created by Paul Hudson on 12/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI

/// Controls the battery level and state for the whole device.
struct StatusBarView: View {
    /// The current battery level of the device, as a value from 0 through 100
    @State private var batteryLevel = 100.0

    /// The current battery state of the device; must be "Charging", "Charged", or "Discharging"
    /// Note: "Charged" looks the same as "Discharging", so it's not included in this screen.
    @State private var batteryState: SimCtl.StatusBar.BatteryState = .charging

    /// The current time to show in the device.
    @State private var time = Date()

    var simulator: Simulator

    var body: some View {
		ScrollView {
			GroupBox(label: Text("Time")) {
				HStack {
					HStack {
						DatePicker("Time:", selection: $time)
						Button("Set", action: setTime)
					}
					.frame(width: 350)
					Spacer()
				}
				.padding()
			}
			.padding()

			GroupBox(label: Text("Battery")) {
				HStack {
					Form {
						Picker("State:", selection: $batteryState.onChange(updateBattery)) {
							ForEach(SimCtl.StatusBar.BatteryState.allCases, id: \.self) { state in
								Text(state.displayName)
							}
						}
						.pickerStyle(PopUpButtonPickerStyle())

						HStack {
							Slider(value: $batteryLevel, in: 0...100, onEditingChanged: levelChanged) {
								Text("Level:")
							}
							Text(Self.percentFormatter.string(for: batteryLevel / 100) ?? "")
							Spacer()
						}
					}
					.frame(width: 350)
					Spacer()
				}
				.padding()
			}
			.padding([.leading, .trailing, .bottom])

			GroupBox(label: Text("Network")) {
				NetworkView(simulator: simulator)
				.padding()
			}
			.padding([.leading, .trailing])

			Spacer()
		}
        .tabItem {
            Text("Status Bar")
        }
    }

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    /// Sends battery updates all at once; simctl gets unhappy if we send them individually.
    func updateBattery() {
        SimCtl.overrideStatusBarBattery(simulator.udid, level: Int(batteryLevel), state: batteryState)
    }

    /// Triggered when the user adjusts the battery level.
    func levelChanged(_ isEditing: Bool) {
        if isEditing == false {
            self.updateBattery()
        }
    }

	/// Changes the system clock to a new value.
    func setTime() {
        SimCtl.overrideStatusBarTime(simulator.udid, time: time)
    }

}

struct BatteryView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarView(simulator: .example)
    }
}

extension SimCtl.StatusBar.BatteryState {
    var displayName: String {
        self.rawValue.capitalized
    }
}
