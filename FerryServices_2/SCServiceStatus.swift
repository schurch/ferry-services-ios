//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class SCServiceStatus: NSObject {
    
    enum SCDisriptionStatus: Int {
        case Unknown = -99
        case Normal = -1
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    var area: String
    var disruptionStatus: SCDisriptionStatus!
    var ferryProvider: String
    var route: String
    var routeId: Int
    var sortOrder: Int
    
    init(data: Dictionary<String, AnyObject>) {
        area = data["Area"]! as String
        
        if let status = data["DisruptionStatus"]! as? Int {
            disruptionStatus = SCDisriptionStatus.fromRaw(status)
        }
        
        ferryProvider = data["provider"]! as String
        route = data["Route"]! as String
        routeId = data["RouteID"]! as Int
        sortOrder = data["SortOrder"]! as Int
    }
   
}
