//
//  Service.swift
//  FerryServices_2
//
//  Created by Stefan Church on 10/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import Foundation

func == (lhs: Service, rhs: Service) -> Bool {
    return lhs.serviceId == rhs.serviceId
}

enum DisriptionStatus: Int {
    case Unknown = -99
    case Normal = 0
    case SailingsAffected = 1
    case SailingsCancelled = 2
}

class Service {
    var serviceId: Int
    var sortOrder: Int
    var area: String
    var route: String
    var status: DisriptionStatus
    
    var disruptionDetails: String?
    
    init(serviceId: Int, sortOrder: Int, area: String, route: String, status: DisriptionStatus) {
        self.serviceId = serviceId
        self.sortOrder = sortOrder
        self.area = area
        self.route = route
        self.status = status
    }
    
    convenience init?(json: [String: AnyObject]) {
        if let serviceId = json["service_id"] as? Int,
            sortOrder = json["sort_order"] as? Int,
            area = json["area"] as? String,
            route = json["route"] as? String,
            status = json["status"] as? Int {
                self.init(serviceId: serviceId, sortOrder: sortOrder, area: area, route: route, status: DisriptionStatus(rawValue: status)!)
                
                if let disruptionDetails = json["disruption_details"] as? String {
                    self.disruptionDetails = disruptionDetails
                }
        }
        else {
            return nil
        }
        
    }
}