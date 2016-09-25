//
//  Vessel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Vessel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        //"2016-02-06 00:49:32 +0000"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    var mmsi: Int
    var updated: Date?
    var name: String
    var latitude: Double
    var longitude: Double
    var course: Double?
    var speed: Double?
    var status: Int?
    
    init(data: [String: AnyObject]) {
        let json = JSON(data)
        
        mmsi = json["mmsi"].intValue
        
        if let updatedDate = json["updated"].string {
            updated = Vessel.dateFormatter.date(from: updatedDate)
        }
        
        name = json["name"].stringValue
        latitude = json["latitude"].doubleValue
        longitude = json["longitude"].doubleValue
        course = json["course"].double
        speed = json["speed"].double
        status = json["status"].int
    }
}

func == (lhs: Vessel, rhs: Vessel) -> Bool {
    return lhs.mmsi == rhs.mmsi
}
