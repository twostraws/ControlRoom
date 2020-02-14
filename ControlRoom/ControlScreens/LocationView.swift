//
//  LocationView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import CoreLocation
import SwiftUI

/// Map view to change simulated user's position
struct LocationView: View {
    var simulator: Simulator

    /// The location that is being simulated
    @State var currentLocation: CLLocation?

    /// User-facing text describing `currentLocation`
    var locationText: String {
        guard let currentLocation = currentLocation else { return "not set"}
        return String(format: "%.5f, %.5f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
    }

    var body: some View {
        Form {
            Text("Long press to set desired user position, then activate it in the simulator with the bottom button")

            MapView(location: $currentLocation)
                .padding(.bottom, 10)

            HStack {
                Text("Coordinates: \(locationText)")
                Spacer()
                Button("Activate", action: changeLocation)
            }
        }
        .tabItem {
            Text("Location")
        }
        .padding()
    }

    /// Updates the simulated location to the value of `currentLocation`.
    func changeLocation() {
        guard let location = self.currentLocation else { return }

        let coordinate = location.coordinate

        let userInfo: [AnyHashable: Any] = [
            "simulateLocationLatitude": coordinate.latitude,
            "simulateLocationLongitude": coordinate.longitude
        ]

        // An undocumented notification name to change the current simulator's location. From here: https://github.com/lyft/set-simulator-location
        let locationNotificationName = "com.apple.iphonesimulator.simulateLocation"

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
