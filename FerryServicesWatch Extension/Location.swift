//
//  Location.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/08/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import MapKit

struct Location {
    var locationId: Int
    var name: String
    var coordinates: CLLocationCoordinate2D
    
    init(locationId: Int, name: String, coordinates: CLLocationCoordinate2D) {
        self.locationId = locationId
        self.name = name
        self.coordinates = coordinates
    }
}