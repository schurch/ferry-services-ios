//
//  SCRoute.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

class Route {
    
    class func fetchRoutesForServiceId(_ serviceId: Int, date: Date) -> [Route]? {
        let path = Bundle.main.path(forResource: "timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!(database?.open())!) {
            return nil
        }
        
        var query = "SELECT r.routeId as RouteId,\n"
        query += "r.Type as RouteType,\n"
        query += "r.SourceLocationId as SourceLocationId,\n"
        query += "r.DestinationLocationId as DestinationLocationId\n"
        query += "FROM Route r\n"
        query += "WHERE r.ServiceId = (?)"
        
        let resultSet = database?.executeQuery(query, withArgumentsIn: [serviceId])

        var routes = [Route]()
        while (resultSet?.next())! {
            let destination = Location.fetchLocationWithId(Int((resultSet?.int(forColumn: "DestinationLocationId"))!))
            let source = Location.fetchLocationWithId(Int((resultSet?.int(forColumn: "SourceLocationId"))!))
            let serviceId = serviceId
            
            let routeId = Int((resultSet?.int(forColumn: "RouteId"))!)
            let trips: [Trip]? = Trip.fetchTripsForRouteId(routeId, date: date)
            
            let routeType = RouteType(rawValue: Int((resultSet?.int(forColumn: "RouteType"))!))
            
            let route = Route(destination: destination, source: source, serviceId: serviceId, trips: trips, routeType:routeType)
            routes += [route]
        }
    
        database?.close()
        
        return routes
    }
    
    enum RouteType: Int {
        case ferry = 1
        case train = 2
    }
    
    var destination: Location?
    var source: Location?
    var serviceId: Int?
    var trips: [Trip]?
    var routeType: RouteType?
    
    init(destination: Location?, source: Location?, serviceId: Int?, trips: [Trip]?, routeType: RouteType?) {
        self.destination = destination
        self.source = source
        self.serviceId = serviceId
        self.trips = trips
        self.routeType = routeType
    }
    
    func routeDescription() -> String {
        if let source = self.source?.name {
            if let destination = self.destination?.name {
                return "\(source) to \(destination)"
            }
        }
        
        return ""
    }
}
