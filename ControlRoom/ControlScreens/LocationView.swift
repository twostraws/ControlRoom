//
//  LocationView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import SwiftUI
import CoreLocation
/// Map view to change simulated user's position
struct LocationView: View {
    var simulator: Simulator
    @State var currentLocation: CLLocation?

    var locationText: String {
        guard let currentLocation = currentLocation else { return "not set"}
        return "\(currentLocation.coordinate.latitude) - \(currentLocation.coordinate.longitude)"
    }

    var body: some View {
        Form {
            Group {

                Text("Long press to set desired user's position and set it in simulator with bottom button")
            }
            Group {
                MapView(location: $currentLocation)
            }
            Group {
                HStack {
                Text("Coordinates:")
                Text("\(locationText)")
                Spacer()
                Button("Update simulator", action: changeLocation)
                }
            }

        }
        .tabItem {
            Text("Location")
        }
        .padding()
    }

    private let locationNotificationName = "com.apple.iphonesimulator.simulateLocation"
    /// Change current simulator's location
    /// Credits: https://github.com/lyft/set-simulator-location

    func changeLocation() {
        guard let location = self.currentLocation else { return }
        let coordinate = location.coordinate
        let userInfo: [AnyHashable: Any] = [
            "simulateLocationLatitude": coordinate.latitude,
            "simulateLocationLongitude": coordinate.longitude
        ]

        let notification = Notification(name: Notification.Name(rawValue: locationNotificationName),
                                        object: nil,
                                        userInfo: userInfo)

        DistributedNotificationCenter
            .default()
            .post(notification)
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        SystemView(simulator: .example)
    }
}
