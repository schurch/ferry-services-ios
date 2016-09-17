//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import SwiftyJSON

class ServiceStatus: Equatable {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        //"2015-04-18T23:08:00+00:00"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    enum DisriptionStatus: Int {
        case unknown = -99
        case normal = 0
        case sailingsAffected = 1
        case sailingsCancelled = 2
    }
    
    var serviceId: Int?
    var sortOrder: Int?
    var area: String?
    var route: String?
    var updated: Date?
    var disruptionStatus: DisriptionStatus?
    
    init() {
        self.disruptionStatus = .normal
    }
    
    init(data: JSON) {
        
        self.area = data["area"].string
        
        if let disruptionStatus = data["status"].int {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionStatus)
        }
        
        if let updatedDate = data["updated"].string {
            self.updated = DisruptionDetails.dateFormatter.date(from: updatedDate)
        }
        
        self.route = data["route"].string
        self.serviceId = data["service_id"].int
        self.sortOrder = data["sort_order"].int
    }
}

func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
    return lhs.serviceId == rhs.serviceId
}
