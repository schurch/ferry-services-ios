//
//  Journey.swift
//  FerryServices_2
//
//  Created by Stefan Church on 14/06/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

struct Journey {
    var from: String
    var to: String
    var departureHour: Int
    var departureMinute: Int
    var arrivalHour: Int
    var arrivalMinute: Int
    
    var departureTime: String {
        return "\(departureHour.padWithZero()):\(departureMinute.padWithZero())"
    }
    
    var arrivalTime: String {
        return "\(arrivalHour.padWithZero()):\(arrivalMinute.padWithZero())"
    }
    
    init(from: String, to: String, departureHour: Int, departureMinute: Int, runningTimeSeconds: Int) {
        self.from = from
        self.to = to
        self.departureHour = departureHour
        self.departureMinute = departureMinute
        
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        let currentDateComponents = calendar.components([.Year, .Month, .Day], fromDate: NSDate())
        
        let departureComponents = NSDateComponents()
        departureComponents.year = currentDateComponents.year
        departureComponents.month = currentDateComponents.month
        departureComponents.day = currentDateComponents.day
        departureComponents.hour = departureHour
        departureComponents.minute = departureMinute
        departureComponents.second = 0
        
        let departureDate = calendar.dateFromComponents(departureComponents)!
        let arrivalDate = calendar.dateByAddingUnit(.Second, value: runningTimeSeconds, toDate: departureDate, options: [])!
        
        let arrivalComponents = calendar.components([.Hour, .Minute], fromDate: arrivalDate)
        
        self.arrivalHour = arrivalComponents.hour
        self.arrivalMinute = arrivalComponents.minute
    }
}
