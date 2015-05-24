//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public class DisruptionDetails: ServiceStatus {
    
    public var additionalInfo: String?
    public var details: String?
    public var reason: String?
    public var disruptionUpdatedDate: NSDate?
    
    public var hasAdditionalInfo: Bool {
        if self.additionalInfo != nil && !self.additionalInfo!.isEmpty {
            return true
        }
        
        return false
    }
    
    public var lastUpdated: String? {
        if let updatedDate = self.disruptionUpdatedDate  {
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
    
    public override init() {
        super.init()
    }
    
    public override init(data: JSONValue) {
        super.init(data: data)
        
        if let additionalInfo = data["additional_info"].string {
            self.additionalInfo = additionalInfo
        }
        
        if let details = data["disruption_details"].string {
            self.details = details
        }
        
        if let disruptionDate = data["disruption_date"].string {
            self.disruptionUpdatedDate = DisruptionDetails.dateFormatter.dateFromString(disruptionDate)
        }
        
        self.reason = data["disruption_reason"].string
    }
}