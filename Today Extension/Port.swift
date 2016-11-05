//
//  Port.swift
//  FerryServices_2
//
//  Created by Stefan Church on 16/01/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

class Port {
    var name: String
    var latitude: Double
    var longitude: Double
    
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
