//
//  SCLocation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

class StopPoint {
    
    var stopPointId: String
    var name: String
    var latitude: Double
    var longitude: Double
    
    var weather: LocationWeather?
    var weatherFetchError: NSError?
    
    init(stopPointId: String, name: String, latitude: Double, longitude: Double) {
        self.stopPointId = stopPointId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: -
func == (lhs: StopPoint, rhs: StopPoint) -> Bool {
    return lhs.stopPointId == rhs.stopPointId
}
