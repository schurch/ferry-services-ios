//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

struct DisruptionDetails {
    
    enum DisriptionStatus: Int {
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    var additionalInfo: String?
    var details: String?
    var reason: String?
    var updatedDate: NSDate?
    var disruptionStatus: DisriptionStatus?
    
    var hasAdditionalInfo: Bool {
        if self.additionalInfo != nil && !self.additionalInfo!.isEmpty {
            return true
        }
        
        return false
    }
    
    var lastUpdated: String? {
        if let updatedDate = self.updatedDate  {
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let components = calendar.components(NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute, fromDate: updatedDate, toDate: NSDate(), options: nil)
            
            var updated: String
            
            if components.day > 0 {
                let dayText = components.day == 1 ? "day" : "days"
                updated = "\(components.day) \(dayText) ago"
            }
            else if components.hour > 0 {
                let hourText = components.hour == 1 ? "hour" : "hours"
                updated = "\(components.hour) \(hourText) ago"
            }
            else {
                let minuteText = components.minute == 1 ? "minute" : "minutes"
                updated = "\(components.minute) \(minuteText) ago"
            }
            
            return "Last updated \(updated)"
        }
        
        return nil
    }
    
    private static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //2015-04-14T08:47:00+00:00
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss+00:00"
        return formatter
    }()
    
    init () {
        self.disruptionStatus = .Normal
    }
    
    init(data: JSONValue) {
        if let additionalInfo = data["additional_info"].string {
            self.additionalInfo = additionalInfo
        }
        
        if let details = data["disruption_details"].string {
            self.details = details
        }
        
//        if let disruptionDate = data["disruption_date"].string {
//            self.disruptionEndDate = DisruptionDetails.dateFormatter.dateFromString(disruptionDate)
//        }
        
        self.reason = data["disruption_reason"].string
        
        if let updatedDate = data["disruption_date"].string {
            self.updatedDate = DisruptionDetails.dateFormatter.dateFromString(updatedDate)
        }
        
        if let disruptionDetailsStatus = data["status"].integer {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionDetailsStatus)
        }
    }
}