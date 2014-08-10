//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public struct DisruptionDetails {
    
    public enum DisruptionDetailsStatus: Int {
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
        case Information = -1
    }
    
    public var addedBy: String?
    public var addedDate: NSDate?
    public var details: String?
    public var disruptionEndDate: NSDate?
    public var lastUpdatedBy: String?
    public var reason: String?
    public var updatedDate: NSDate?
    public var disruptionStatus: DisruptionDetailsStatus?
    
    private static let dateFormatter :NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        return formatter
    }()
    
    init(data: [String: JSONValue]) {
        self.addedBy = data["AddedByUserID"]?.string
        self.addedDate = DisruptionDetails.dateFormatter.dateFromString(data["AddedTime"]?.string)
        self.details = data["WebText"]?.string
        self.disruptionEndDate = DisruptionDetails.dateFormatter.dateFromString(data["DisruptionEndTime"]?.string)
        self.lastUpdatedBy = data["LastUpdatedBy"]?.string
        self.reason = data["Reason"]?.string
        self.updatedDate = DisruptionDetails.dateFormatter.dateFromString(data["UpdatedTime"]?.string)
        if let disruptionDetailsStatus = data["DisruptionStatus"]?.integer {
            self.disruptionStatus = DisruptionDetailsStatus.fromRaw(disruptionDetailsStatus)
        }
    }
}