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
    static let defaultLat = 37.323056
    static let defaultLong = -122.031944

    /// Saved locations controller.
    @StateObject private var locationsController = LocationsController()
    /// Local search controller.
    @StateObject private var localSearchController = LocalSearchController()
    /// Current table selection binding.
    @State private var previouslyPickedLocation: Location.ID?

    /// Name of the location user is about save.
    @State private var newLocationName = ""
    /// Indicates whether save location alert is currently presented.
    @State private var isShowingNewLocationAlert = false

    /// Placeholder that appears in the local search bar
    @State private var placeholder = "Search"
    /// The query that is typed into the search bar
    @State private var query = ""
    /// Results returned from the local search
    @State private var results: [LocalSearchResult] = []
    /// Controls presentation of the results dropdown
    @State private var presentResults = false
    /// Keeps track of which search item is being currently hovered over
    @State private var lastHoverId: UUID?

    @State private var latitudeText = "\(defaultLat)"
    @State private var longitudeText = "\(defaultLong)"
    /// The location that is being simulated
    @State private var currentLocation = Location(id: UUID(), name: "", latitude: defaultLat, longitude: defaultLong)
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
                Text("Move the map, paste in coordinates or search for a location, then click Activate to update the simulator to match your centered coordinate.")

                GeometryReader { proxy in
                    HStack {
                        ZStack(alignment: .topLeading) {
                            VStack {
                                SearchField(placeholder, text: $query, onClear: { onSearchClear() })
                                    .onReceive(query.publisher) { _ in
                                        performLocalSearch()
                                    }
                                ZStack {
                                    Map(coordinateRegion: $currentLocation.region, annotationItems: annotations) { location in
                                        MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), tint: .red)
                                    }
                                    .cornerRadius(5)

                                    Circle()
                                        .stroke(Color.blue, lineWidth: 4)
                                        .frame(width: 20)
                                }
                            }
                            VStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(results) { result in
                                        LocalSearchRowView(lastHoverId: $lastHoverId, result: result, onTap: {
                                            selectResult(result)
                                        })
                                        .onHover { isHovered in
                                            if isHovered {
                                                lastHoverId = result.id
                                            } else if lastHoverId == result.id {
                                                lastHoverId = nil
                                            }
                                        }
                                    }

                                    if results.isEmpty {
                                        Text("No suggestions found")
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                            }
                            .frame(maxWidth: .infinity)
                            .background(.background)
                            .padding(.top, 24)
                            .cornerRadius(12)
                            .opacity(presentResults ? 1 : 0)
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
                    Button("Copy", action: copyCoordinatesToClipboard)
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

    /// Takes the entered query and performs a local search. If the query is a pasted-in coordinate,
    /// it will return a `Location` immediately.
    private func performLocalSearch() {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            presentResults = false
            NSApp.keyWindow?.makeFirstResponder(nil)
            return
        }

        let immediateResult = localSearchController.search(for: query, around: currentLocation) { newResults in
            results = Array(newResults.prefix(5))
            presentResults = true
        }

        if let immediateResult {
            currentLocation = immediateResult
            presentResults = false
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    /// If the close button on the search bar is closed, close the dropdown list
    private func onSearchClear() {
        query = ""
        presentResults = false
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

    /// If a result is chosen, request the coordinate and present the location on the map
    private func selectResult(_ result: LocalSearchResult) {
        localSearchController.select(result) { location in
            currentLocation = location
            presentResults = false
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    /// Copies `currentLocation` to the clipboard
    private func copyCoordinatesToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(currentLocation.toString(), forType: .string)
    }

    /// Randomly generates a new location slightly offset from the currentLocation
    private func jitterLocation() {
        let lat = currentLocation.center.latitude + (Double.random(in: -0.0001...0.0001))
        let long = currentLocation.center.longitude + (Double.random(in: -0.0001...0.0001))
        jitteredLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        changeLocation()
    }

    /// Saves currently selected location to user's collection.
    private func savePickedLocation() {
        let latitude = currentLocation.center.latitude
        let longitude = currentLocation.center.longitude
        locationsController.create(name: newLocationName, latitude: latitude, longitude: longitude)
        newLocationName = ""
    }

    /// Updates current location on the map when saved location is selected from the table.
    private func updatePickedLocation() {
        guard let location = locationsController.item(with: previouslyPickedLocation) else { return }
        currentLocation = location
    }
}
