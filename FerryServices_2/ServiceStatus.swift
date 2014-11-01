//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

struct ServiceStatus: Equatable {
    
    enum DisriptionStatus: Int {
        case Unknown = -99
        case Normal = -1
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    var area: String?
    var disruptionStatus: DisriptionStatus?
    var ferryProvider: String?
    var route: String?
    var serviceId: Int?
    var sortOrder: Int?
    
    init(data: JSONValue) {
        
        self.area = data["Area"].string
        
        if let disruptionStatus = data["DisruptionStatus"].integer {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionStatus)
        }
        
        self.ferryProvider = data["provider"].string
        self.route = data["Route"].string
        self.serviceId = data["RouteID"].integer
        self.sortOrder = data["SortOrder"].integer
    }
}

func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
    return lhs.serviceId == rhs.serviceId
}
