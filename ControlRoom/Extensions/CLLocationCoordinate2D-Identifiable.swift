//
//  CLLocationCoordinate2D-Identifiable.swift
//  ControlRoom
//
//  Created by Paul Hudson on 28/01/2021.
//  Copyright © 2021 Paul Hudson. All rights reserved.
//

import CoreLocation
import Foundation

#if swift(>=5.10)
extension CLLocationCoordinate2D: @retroactive Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}
#else
extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}
#endif