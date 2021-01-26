//
//  MapView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import MapKit
import SwiftUI

/// A wrapper around MKMapView so we can get drop a user pin.
struct MapView: NSViewRepresentable {
    @Binding var location: CLLocation?

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $location)
    }

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        context.coordinator.mapView = mapView

        let gesture = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        mapView.addGestureRecognizer(gesture)

        return mapView
    }

    func updateNSView(_ uiView: MKMapView, context: Context) { }

    class Coordinator: NSObject {
        let binding: Binding<CLLocation?>
        weak var mapView: MKMapView?

        init(binding: Binding<CLLocation?>) {
            self.binding = binding
            super.init()
        }

        @objc func handleLongPress(_ gesture: NSPressGestureRecognizer) {
            guard let mapView = mapView else { return }

            let touchPoint = gesture.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            binding.wrappedValue = location

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(annotation)
        }
    }
}
