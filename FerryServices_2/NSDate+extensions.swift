//
//  NSDate+Additions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

extension NSDate {
    class func stripTimeComponentsFromDate(date: NSDate) -> NSDate {
        if let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian) {
            calendar.timeZone = NSTimeZone(abbreviation: "UTC")!
            
            let components = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: date)
            
            components.hour = 0
            components.minute = 0
            components.second = 0
            
            let date = calendar.dateFromComponents(components)
            
            return date!
        }
        else {
            return NSDate()
        }
    }
}
