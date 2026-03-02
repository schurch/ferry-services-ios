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
        let rect = locations.reduce(MKMapRect.null) { rect, location in
            rect.union(
                MKMapRect(
                    origin: MKMapPoint.init(
                        CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                    ),
                    size: MKMapSize(width: 0.1, height: 0.1)
                )
            )
        }
        
        return rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
    }
}
