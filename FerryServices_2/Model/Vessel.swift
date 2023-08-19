//
//  Vessel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

struct Vessel: Codable, Equatable, Hashable, Identifiable {
    var id: Int { mmsi }
    
    let mmsi: Int
    let name: String
    let speed: Double?
    let course: Double?
    let latitude: Double
    let longitude: Double
    let lastReceived: Date
}

func == (lhs: Vessel, rhs: Vessel) -> Bool {
    return lhs.mmsi == rhs.mmsi
}
