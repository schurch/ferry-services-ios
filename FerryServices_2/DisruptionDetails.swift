//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

struct DisruptionDetails {
    
    enum DisruptionDetailsStatus: Int {
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
        case Information = -1
    }
    
    var addedBy: String?
    var addedDate: NSDate?
    var additionalInfo: String?
    var details: String?
    var disruptionEndDate: NSDate?
    var lastUpdatedBy: String?
    var reason: String?
    var updatedDate: NSDate?
    var disruptionStatus: DisruptionDetailsStatus?
    
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
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        return formatter
    }()
    
    init () {
        self.disruptionStatus = .Normal
    }
    
    init(data: [String: JSONValue]) {
        self.addedBy = data["AddedByUserID"]?.string
        
        if let addedDate = data["AddedTime"]?.string {
            self.addedDate = DisruptionDetails.dateFormatter.dateFromString(addedDate)
        }
        
        if let additionalInfo = data["accessDisruption"]?.string {
            self.additionalInfo = additionalInfo
        }
        
        if let details = data["WebText"]?.string {
            self.details = details
        }
        
        if let disruptionDate = data["DisruptionEndTime"]?.string {
            self.disruptionEndDate = DisruptionDetails.dateFormatter.dateFromString(disruptionDate)
        }
        
        self.lastUpdatedBy = data["LastUpdatedBy"]?.string
        self.reason = data["Reason"]?.string
        
        if let updatedDate = data["UpdatedTime"]?.string {
            self.updatedDate = DisruptionDetails.dateFormatter.dateFromString(updatedDate)
        }
        
        if let disruptionDetailsStatus = data["DisruptionStatus"]?.integer {
            self.disruptionStatus = DisruptionDetailsStatus(rawValue: disruptionDetailsStatus)
        }
    }
}