//
//  RouteDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

struct RouteDetails {
    
    var area: String?
    var route: String?
    var routeId: Int?
    
    init(data: [String: JSONValue]) {
        self.area = data["Area"]?.string
        self.route = data["Route"]?.string
        self.routeId = data["RouteID"]?.integer
    }
}