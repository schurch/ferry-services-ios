//
//  NSDate+Additions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

extension Date {
    static func stripTimeComponentsFromDate(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        var components = (calendar as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second], from: date)
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let date = calendar.date(from: components)
        
        return date!
    }
}
