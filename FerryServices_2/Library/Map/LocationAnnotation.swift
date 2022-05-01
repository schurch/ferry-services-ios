//
//  LocationAnnotation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/05/22.
//  Copyright © 2022 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

class LocationAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    @objc dynamic var title: String?
    
    init(location: Service.Location) {
        self.coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        self.title = location.name
    }
}
