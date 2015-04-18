//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

class ServiceStatus: Equatable {
    
    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //2015-04-14T08:47:00+00:00
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss+00:00"
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
    var disruptionStatus: DisriptionStatus?
    
    init() {
        self.disruptionStatus = .Normal
    }
    
    init(data: JSONValue) {
        
        self.area = data["area"].string
        
        if let disruptionStatus = data["status"].integer {
            self.disruptionStatus = DisriptionStatus(rawValue: disruptionStatus)
        }
        
        self.route = data["route"].string
        self.serviceId = data["service_id"].integer
        self.sortOrder = data["sort_order"].integer
    }
}

func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
    return lhs.serviceId == rhs.serviceId
}
