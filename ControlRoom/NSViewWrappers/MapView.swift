//
//  MapView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//
import SwiftUI
import MapKit
import AppKit

class CustomMapView: MKMapView {

    var longPressClosure: (CLLocation?) -> Void = { _ in}

    @objc func handleLongPress(_ gesture: NSPressGestureRecognizer) {
        let mapView = self
        let touchPoint = gesture.location(in: mapView)
        let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        longPressClosure(location)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
    }
}

struct MapView: NSViewRepresentable {

    @Binding var location: CLLocation?

    func makeNSView(context: Context) -> MKMapView {

        let mapView = CustomMapView()
        mapView.longPressClosure = { self.location = $0 }
        let gesture = NSPressGestureRecognizer(target: mapView, action: #selector(mapView.handleLongPress(_:)))
        mapView.addGestureRecognizer(gesture)

        return mapView
    }
    func updateNSView(_ uiView: MKMapView, context: Context) {
    }
    private func updateAnnotations(from mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        //      mapView.addAnnotations(newAnnotations)
    }
}
