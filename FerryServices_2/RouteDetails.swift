//
//  RouteDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public struct RouteDetails {
    
    public var area: String?
    public var route: String?
    public var routeId: Int?
    
    init(data: [String: JSONValue]) {
        self.area = data["Area"]?.string
        self.route = data["Route"]?.string
        self.routeId = data["RouteID"]?.integer
    }
}