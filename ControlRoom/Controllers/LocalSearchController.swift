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
    private var lastQuery: String = ""
    private var callback: (([LocalSearchResult]) -> Void)?

    private lazy var localSearchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
        return completer
    }()

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
            center: location.toCLLocationCoordinate2D(),
            latitudinalMeters: CLLocationDistance(20000),
            longitudinalMeters: CLLocationDistance(20000)
        )

        return nil
    }

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

extension LocalSearchController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard let callback else { return }
        let results = completer.results.map {
            LocalSearchResult( result: $0 )
        }
        callback(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
}
