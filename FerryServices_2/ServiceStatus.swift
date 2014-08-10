//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public struct ServiceStatus {
    
    public enum DisriptionStatus: Int {
        case Unknown = -99
        case Normal = -1
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    public var area: String?
    public var disruptionStatus: DisriptionStatus?
    public var ferryProvider: String?
    public var route: String?
    public var routeId: Int?
    public var sortOrder: Int?
    
    init(data: JSONValue) {
        
        self.area = data["Area"].string
        
        if let disruptionStatus = data["DisruptionStatus"].integer {
            self.disruptionStatus = DisriptionStatus.fromRaw(disruptionStatus)
        }
        
        self.ferryProvider = data["provider"].string
        self.route = data["Route"].string
        self.routeId = data["RouteID"].integer
        self.sortOrder = data["SortOrder"].integer
    }
}
