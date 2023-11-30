//
//  LocalSearchController.swift
//  ControlRoom
//
//  Created by John McEvoy on 29/11/2023.
//  Copyright © 2023 Paul Hudson. All rights reserved.
//

import Foundation
import MapKit

@MainActor
class LocalSearchController: NSObject, ObservableObject {
    /// Prevents duplicate queries from being made
    private var lastQuery: String = ""

    /// Completion handler is called by the `MKLocalSearchCompleter` success callback
    private var callback: (([LocalSearchResult]) -> Void)?

    /// the MKLocalSearchCompleter used to make local search requests
    private lazy var localSearchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
        return completer
    }()

    /**
     Finds places and POIs using a query string and a geographical point to focus on.

     - Parameter for: The partial (autocomplete) query to search for.
     - Parameter around: Provides a hint for `MKLocalSearchCompleter` to search around a geographical point.
     - Parameter completion: Called if valid search results are found.

     - Returns: If a location is found immediately (a coordinate was pasted in, for example), returns a `Location`.
     */
    func search(for query: String,
                around location: Location,
                completion: @escaping ([LocalSearchResult]) -> Void) -> Location? {
        guard query.isNotEmpty, query != lastQuery else { return nil }
        callback = completion
        lastQuery = query

        if let location = parseCoordinates(query) {
            return location
        }

        localSearchCompleter.queryFragment = query
        localSearchCompleter.region = MKCoordinateRegion(
            center: location.center,
            latitudinalMeters: CLLocationDistance(20000),
            longitudinalMeters: CLLocationDistance(20000)
        )

        return nil
    }

    /**
     Converts an incomplete `LocalSearchResult` to a `Location` with coordinates and map bounds.

     - Parameter result: The `LocalSearchResult` to convert.
     - Parameter completion: Called if a valid `Location` is created.
     */
    func select(_ result: LocalSearchResult, completion: @escaping (Location) -> Void) {
        guard let completer = result.completer else { return }

        Task {
            do {
                let request = MKLocalSearch.Request(completion: completer)
                let response = try await MKLocalSearch(request: request).start()
                guard let mapItem = response.mapItems.first else { return }
                let location = Location(
                    id: result.id,
                    name: result.title,
                    latitude: mapItem.placemark.coordinate.latitude,
                    longitude: mapItem.placemark.coordinate.longitude,
                    latitudeDelta: response.boundingRegion.span.latitudeDelta,
                    longitudeDelta: response.boundingRegion.span.longitudeDelta)
                completion(location)
            } catch {
                print("\(error)")
            }
        }
    }

    /// Uses a regex to detect if a string is a lat/long coordinate (e.g. `'37.33467, -122.00898'`)
    private func parseCoordinates(_ coordinateString: String) -> Location? {
        do {
            let regexSearch = try Regex("^-?(?:[1-8]?\\d(?:\\.\\d+)?|90(?:\\.0+)?),\\s*-?(?:180(?:\\.0+)?|1[0-7]\\d(?:\\.\\d+)?|\\d{1,2}(?:\\.\\d+)?)$")

            guard coordinateString.ranges(of: regexSearch).isNotEmpty else {
                return nil
            }

            let components = coordinateString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

            guard let latitude = Double(components[0]), let longitude = Double(components[1]) else {
                return nil
            }

            return Location(
                id: UUID(),
                name: "Map coordinate",
                latitude: latitude,
                longitude: longitude)

        } catch {
            return nil
        }
    }
}

/// Adds `MKLocalSearchCompleterDelegate` conformance so the controller can use the delegate's callback methods
extension LocalSearchController: MKLocalSearchCompleterDelegate {
    /// Called if `MKLocalSearchCompleter` return valid results from a query string
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard let callback else { return }
        let results = completer.results.map {
            LocalSearchResult( result: $0 )
        }
        callback(results)
    }

    /// Called if `MKLocalSearchCompleter` encounters an error
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
}
