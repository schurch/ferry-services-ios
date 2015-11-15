//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import SwiftyJSON

class ServiceStatus: Equatable {
    
    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //"2015-04-18T23:08:00+00:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    enum DisriptionStatus: Int {
        case Unknown = -99
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    var serviceId: Int?
    var sortOrder: Int?
    var area: String?
    var route: String?
    var updated: NSDate?
    var disruptionStatus: DisriptionStatus?
    
    init() {
        self.disruptionStatus = .Normal
    }
    
    init(data: JSON) {
        
        self.area = data["area"].string
        
        if let disruptionStatus = data["status"].int {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionStatus)
        }
        
        if let updatedDate = data["updated"].string {
            self.updated = DisruptionDetails.dateFormatter.dateFromString(updatedDate)
        }
        
        self.route = data["route"].string
        self.serviceId = data["service_id"].int
        self.sortOrder = data["sort_order"].int
    }
}

func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
    return lhs.serviceId == rhs.serviceId
}
