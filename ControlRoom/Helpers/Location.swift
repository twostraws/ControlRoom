//
//  Location.swift
//  ControlRoom
//
//  Created by Alexander Chekel on 17.11.2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

/// The user's saved location.
struct Location: Identifiable, Codable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var latitudeDelta: Double = 15
    var longitudeDelta: Double = 15

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        } set {
            latitude = newValue.center.latitude
            longitude = newValue.center.longitude
            latitudeDelta = newValue.span.latitudeDelta
            longitudeDelta = newValue.span.longitudeDelta
        }
    }

    func toString() -> String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }
}
