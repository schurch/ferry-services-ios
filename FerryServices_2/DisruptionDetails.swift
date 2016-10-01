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
            return "Last updated \(updatedDate.relativeTimeSinceNowText())"
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
