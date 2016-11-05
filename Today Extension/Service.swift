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
    case unknown = -99
    case normal = 0
    case sailingsAffected = 1
    case sailingsCancelled = 2
}

class Service: Equatable {
    
    static let defaultServices: [Service] = {
        let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json")!
        let serviceData = try! Data(contentsOf: URL(fileURLWithPath: defaultServicesFilePath), options: .mappedIfSafe)
        let serviceStatusData = try! JSONSerialization.jsonObject(with: serviceData, options: []) as! [[String: AnyObject]]
        
        let serviceStatuses: [Service] = serviceStatusData.flatMap { Service(json: $0) }
        let sortedServiceStatuses = serviceStatuses.sorted(by: { $0.sortOrder < $1.sortOrder })
        
        return sortedServiceStatuses
    }()
    
    var serviceId: Int
    var sortOrder: Int
    var area: String
    var isDefault: Bool // Set if should be default service on startup
    var route: String
    var status: DisriptionStatus

    var ports: [Port]?
    var disruptionDetails: String?
    
    init(serviceId: Int, sortOrder: Int, area: String, route: String, status: DisriptionStatus) {
        self.serviceId = serviceId
        self.sortOrder = sortOrder
        self.area = area
        self.isDefault = false
        self.route = route
        self.status = status
    }
    
    convenience init?(json: [String: AnyObject]) {
        if let serviceId = json["service_id"] as? Int,
            let sortOrder = json["sort_order"] as? Int,
            let area = json["area"] as? String,
            let route = json["route"] as? String,
            let status = json["status"] as? Int {
                self.init(serviceId: serviceId, sortOrder: sortOrder, area: area, route: route, status: DisriptionStatus(rawValue: status)!)
                
                if let disruptionDetails = json["disruption_details"] as? String {
                    self.disruptionDetails = disruptionDetails
                }
                
                if let portsData = json["ports"] as? [[String: AnyObject]] {
                    let ports: [Port?] = portsData.map { portData in
                        if let name = portData["name"] as? String,
                            let latitude = portData["latitude"] as? Double,
                            let longitude = portData["longitude"] as? Double {
                                return Port(name: name, latitude: latitude, longitude: longitude)
                            
                        }
                        else {
                            return nil
                        }
                    }
                    
                    self.ports = ports.flatMap { $0 }
                }
        }
        else {
            return nil
        }
        
    }
}
