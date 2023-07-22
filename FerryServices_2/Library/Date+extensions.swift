//
//  NSDate+Additions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

extension Date {
    
    static let timeFormatStyle = {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = TimeZone(identifier: "Europe/London")!
        return style
    }()
    
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
    
    func relativeTimeSinceNowText() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: self, to: Date())
        
        if components.day! > 0 {
            let dayText = components.day == 1 ? "day" : "days"
            return "\(components.day!) \(dayText) ago"
        }
        else if components.hour! > 0 {
            let hourText = components.hour == 1 ? "hour" : "hours"
            return "\(components.hour!) \(hourText) ago"
        }
        else if components.minute! > 0 {
            let minuteText = components.minute == 1 ? "minute" : "minutes"
            return "\(components.minute!) \(minuteText) ago"
        }
        else {
            let secondsText = components.second == 1 ? "second" : "seconds"
            return "\(components.second!) \(secondsText) ago"
        }
    }
    
}
