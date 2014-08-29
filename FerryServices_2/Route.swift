//
//  SCRoute.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

public struct Route {
    
    enum RouteType: Int {
        case Ferry = 1
        case Train = 2
    }
    
    var destination: Location?
    var source: Location?
    var serviceId: Int?
    var trips: [Trip]?
    
    class func fetchRoutesForServiceId(serviceId: Int, onDate date: NSDate) -> [Route]? {
        
    }
    
    func routeDescription() -> String {
        return "\(self.source?.name) to \(self.destination?.name)"
    }
}
