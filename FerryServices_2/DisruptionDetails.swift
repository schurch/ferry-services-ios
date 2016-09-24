//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import SwiftyJSON

class DisruptionDetails: ServiceStatus {
    
    var additionalInfo: String?
    var details: String?
    var reason: String?
    var disruptionUpdatedDate: Date?
    
    var hasAdditionalInfo: Bool {
        if self.additionalInfo != nil && !self.additionalInfo!.isEmpty {
            return true
        }
        
        return false
    }
    
    var lastUpdated: String? {
        if let updatedDate = self.disruptionUpdatedDate  {
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            let components = (calendar as NSCalendar).components([NSCalendar.Unit.day, NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: updatedDate, to: Date(), options: [])
            
            var updated: String
            
            if components.day! > 0 {
                let dayText = components.day == 1 ? "day" : "days"
                updated = "\(components.day) \(dayText) ago"
            }
            else if components.hour! > 0 {
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
    
    override init() {
        super.init()
    }
    
    override init(data: JSON) {
        super.init(data: data)
        
        if let additionalInfo = data["additional_info"].string {
            self.additionalInfo = additionalInfo
        }
        
        if let details = data["disruption_details"].string {
            self.details = details
        }
        
        if let disruptionDate = data["disruption_date"].string {
            self.disruptionUpdatedDate = DisruptionDetails.dateFormatter.date(from: disruptionDate)
        }
        
        self.reason = data["disruption_reason"].string
    }
}
