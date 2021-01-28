//
//  LocationView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import MapKit
import SwiftUI

/// Map view to change simulated user's position
struct LocationView: View {
    @ObservedObject var controller: SimulatorsController
    let simulator: Simulator

    /// The location that is being simulated
    @State private var currentLocation = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.323056, longitude: -122.031944),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
    @State private var pinnedLocation: CLLocationCoordinate2D?

    var annotations: [CLLocationCoordinate2D] {
        if let pinnedLocation = pinnedLocation {
            return [pinnedLocation]
        } else {
            return []
        }
    }

    /// User-facing text describing `currentLocation`
    var locationText: String {
        String(format: "%.5f, %.5f", currentLocation.center.latitude, currentLocation.center.longitude)
    }

    var body: some View {
        Form {
            Text("Move the map wherever you want, then click Activate to update the simulator to match your centered coordinate.")

            ZStack {
                Map(coordinateRegion: $currentLocation, annotationItems: annotations) { location in
                    MapPin(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                }

                Circle()
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 20)
            }
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
        let coordinate = currentLocation.center
        pinnedLocation = coordinate

        let simulatorIds: [String]

        if simulator.isDefault {
            simulatorIds = controller.simulators
                .filter { $0.state == .booted && !$0.isDefault }
                .map(\.udid)
        } else {
            simulatorIds = [simulator.id]
        }

        let userInfo: [AnyHashable: Any] = [
            "simulateLocationLatitude": coordinate.latitude,
            "simulateLocationLongitude": coordinate.longitude,
            "simulateLocationDevices": simulatorIds
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
