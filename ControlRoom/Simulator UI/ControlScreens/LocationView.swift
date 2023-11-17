//
//  LocationView.swift
//  ControlRoom
//
//  Created by Stefano Mondino on 13/02/2020.
//  Copyright © 2020 Paul Hudson. All rights reserved.
//

import MapKit
import SwiftUI
import CoreLocation

/// Map view to change simulated user's position
struct LocationView: View {
    @ObservedObject var controller: SimulatorsController
    let simulator: Simulator
    static let DEFAULT_LAT = 37.323056
    static let DEFAULT_LNG = -122.031944

    @StateObject private var locationsController = LocationsController()
    @State private var previouslyPickedLocation: Location.ID?

    @State private var newLocationName = ""
    @State private var isShowingNewLocationAlert = false

    @State private var latitudeText = "\(DEFAULT_LAT)"
    @State private var longitudeText = "\(DEFAULT_LNG)"
    /// The location that is being simulated
    @State private var currentLocation = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: DEFAULT_LAT, longitude: DEFAULT_LNG),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
    @State private var pinnedLocation: CLLocationCoordinate2D?

    /// A randomly generated location offset from the currentLocation.
    /// Non-nil only when jittering is enabled.
    @State private var jitteredLocation: CLLocationCoordinate2D?

    @State private var isJittering: Bool = false
    private let jitterTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var annotations: [CLLocationCoordinate2D] {
        if let pinnedLocation = pinnedLocation {
            return [pinnedLocation]
        } else {
            return []
        }
    }

    /// User-facing text describing `currentLocation`
    var locationText: String {
        let location = jitteredLocation ?? currentLocation.center
        return String(format: "%.5f, %.5f", location.latitude, location.longitude)
    }

    var body: some View {
        Form {
            VStack {
                Text("Move the map wherever you want, then click Activate to update the simulator to match your centered coordinate.")

                HStack(spacing: 10.0) {
                    TextField("Latitude", text: $latitudeText)
                        .textFieldStyle(.roundedBorder)

                    TextField("Longitude", text: $longitudeText)
                        .textFieldStyle(.roundedBorder)
                }

                Button("Update coordinates") {
                    if let latitude = Double(latitudeText),
                       let longitude = Double(longitudeText) {
                        self.currentLocation = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15))
                    }
                }

                GeometryReader { proxy in
                    HStack {
                        ZStack {
                            Map(coordinateRegion: $currentLocation, annotationItems: annotations) { location in
                                MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                            }
                            .cornerRadius(5)

                            Circle()
                                .stroke(Color.blue, lineWidth: 4)
                                .frame(width: 20)
                        }
                        .keyboardShortcut(.defaultAction)

                        Table(of: Location.self, selection: $previouslyPickedLocation.onChange(updatePickedLocation)) {
                            TableColumn("Saved locations", value: \.name)
                        } rows: {
                            ForEach(locationsController.locations) { location in
                                TableRow(location)
                                    .contextMenu {
                                        Button("Delete") {
                                            locationsController.delete(location.id)
                                        }
                                    }
                            }
                        }
                        .cornerRadius(5)
                        .frame(width: proxy.size.width * 0.3)
                    }
                }
                .padding(.bottom, 10)

                HStack {
                    Text("Coordinates: \(locationText)")
                        .textSelection(.enabled)
                    Spacer()
                    Toggle("Jitter location", isOn: $isJittering)
                        .toggleStyle(.checkbox)
                    Button("Activate", action: changeLocation)
                    Button("Save") {
                        isShowingNewLocationAlert.toggle()
                    }
                }
            }
        }
        .tabItem {
            Text("Location")
        }
        .padding()
        .onReceive(jitterTimer) { _ in
            guard isJittering else {
                jitteredLocation = nil
                return
            }

            jitterLocation()
        }
        .alert("Save location", isPresented: $isShowingNewLocationAlert) {
            TextField("Name", text: $newLocationName)
            Button("Save", action: savePickedLocation)
            Button("Cancel", role: .cancel) { }
        }
    }

    /// Updates the simulated location to the value of `currentLocation`.
    func changeLocation() {
        let coordinate = jitteredLocation ?? currentLocation.center
        pinnedLocation = coordinate

        SimCtl.execute(.location(deviceId: simulator.udid, latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    /// Randomly generates a new location slightly offset from the currentLocation
    private func jitterLocation() {
        let lat = currentLocation.center.latitude + (Double.random(in: -0.0001...0.0001))
        let long = currentLocation.center.longitude + (Double.random(in: -0.0001...0.0001))
        jitteredLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        changeLocation()
    }

    private func savePickedLocation() {
        let latitude = currentLocation.center.latitude
        let longitude = currentLocation.center.longitude
        locationsController.create(name: newLocationName, latitude: latitude, longitude: longitude)

        newLocationName = ""
    }

    private func updatePickedLocation() {
        guard let location = locationsController.item(with: previouslyPickedLocation) else { return }

        currentLocation = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    }
}
