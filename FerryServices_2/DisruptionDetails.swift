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
    var details: String?
    var disruptionEndDate: NSDate?
    var lastUpdatedBy: String?
    var reason: String?
    var updatedDate: NSDate?
    var disruptionStatus: DisruptionDetailsStatus?
    
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
        
        self.details = data["WebText"]?.string
        
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