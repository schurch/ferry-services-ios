//
//  SCRoute.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

class Route {
    
    class func fetchRoutesForServiceId(serviceId: Int, date: NSDate) -> [Route]? {
        let path = NSBundle.mainBundle().pathForResource("timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!database.open()) {
            return nil
        }
        
        var query = "SELECT r.routeId as RouteId,\n"
        query += "r.Type as RouteType,\n"
        query += "r.SourceLocationId as SourceLocationId,\n"
        query += "r.DestinationLocationId as DestinationLocationId\n"
        query += "FROM Route r\n"
        query += "WHERE r.ServiceId = (?)"
        
        let resultSet = database.executeQuery(query, withArgumentsInArray: [serviceId])

        var routes = [Route]()
        while (resultSet.next()) {
            let destination = Location.fetchLocationWithId(Int(resultSet.intForColumn("DestinationLocationId")))
            let source = Location.fetchLocationWithId(Int(resultSet.intForColumn("SourceLocationId")))
            let serviceId = serviceId
            let trips: [Trip]? = nil
            let routeType = RouteType.fromRaw(Int(resultSet.intForColumn("RouteType")))
            routes += [Route(destination: destination, source: source, serviceId: serviceId, trips: trips, routeType:routeType)]
        }
    
        database.close()
        
        return routes
    }
    
    enum RouteType: Int {
        case Ferry = 1
        case Train = 2
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
        return "\(self.source?.name) to \(self.destination?.name)"
    }
}
