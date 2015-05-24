//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public class ServiceStatus: Equatable {
    
    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //"2015-04-18T23:08:00+00:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    public enum DisriptionStatus: Int {
        case Unknown = -99
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    public var serviceId: Int?
    public var sortOrder: Int?
    public var area: String?
    public var route: String?
    public var updated: NSDate?
    public var disruptionStatus: DisriptionStatus?
    
    public init() {
        self.disruptionStatus = .Normal
    }
    
    public init(data: JSONValue) {
        
        self.area = data["area"].string
        
        if let disruptionStatus = data["status"].integer {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionStatus)
        }
        
        if let updatedDate = data["updated"].string {
            self.updated = DisruptionDetails.dateFormatter.dateFromString(updatedDate)
        }
        
        self.route = data["route"].string
        self.serviceId = data["service_id"].integer
        self.sortOrder = data["sort_order"].integer
    }
}

public func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
    return lhs.serviceId == rhs.serviceId
}
