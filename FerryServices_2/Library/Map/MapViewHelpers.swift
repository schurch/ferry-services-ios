//
//  MapViewHelpers.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/05/22.
//  Copyright © 2022 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

class MapViewHelpers {
    static func calculateMapRect(forLocations locations: [Service.Location]) -> MKMapRect {
        let coordinates = locations.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        return calculateMapRect(forCoordinates: coordinates)
    }

    static func calculateMapRect(forCoordinates coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        guard !coordinates.isEmpty else { return MKMapRect.null }

        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            rect.union(
                MKMapRect(
                    origin: MKMapPoint(coordinate),
                    size: MKMapSize(width: 0.1, height: 0.1)
                )
            )
        }

        return rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
    }
}
