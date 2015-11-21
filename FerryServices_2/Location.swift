//
//  SCLocation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import FMDB

class Location : Hashable {
    
    class func fetchLocations() -> [Location]? {
        let path = NSBundle.mainBundle().pathForResource("timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!database.open()) {
            return nil
        }
        
        let query = "SELECT l.Name, l.Latitude, l.Longitude FROM Location l"
        
        let resultSet = database.executeQuery(query, withArgumentsInArray: nil)
        var locations = [Location]()
        
        while (resultSet.next()) {
            let name = resultSet.stringForColumn("Name")
            let latitude = resultSet.doubleForColumn("Latitude")
            let longitude = resultSet.doubleForColumn("Longitude")
            locations += [Location(name: name, latitude: latitude, longitude: longitude)]
        }
        
        database.close()
        
        return locations
    }
    
    class func fetchLocationsForSericeId(serviceId: Int) -> [Location]? {
        let path = NSBundle.mainBundle().pathForResource("timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!database.open()) {
            return nil
        }
        
        var query = "SELECT l.Name, l.Latitude, l.Longitude\n"
        query += "FROM Location l\n"
        query += "WHERE l.locationId IN (\n"
        query += "SELECT r.sourceLocationId\n"
        query += "FROM Route r\n"
        query += "WHERE r.serviceId = (?) AND r.Type = 1\n"
        query += "UNION\n"
        query += "SELECT r.destinationLocationId\n"
        query += "FROM Route r\n"
        query += "WHERE r.serviceId = (?) AND r.Type = 1\n"
        query += ")"
        
        let resultSet = database.executeQuery(query, withArgumentsInArray: [serviceId, serviceId])
        var locations = [Location]()
        
        while (resultSet.next()) {
            let name = resultSet.stringForColumn("Name")
            let latitude = resultSet.doubleForColumn("Latitude")
            let longitude = resultSet.doubleForColumn("Longitude")
            locations += [Location(name: name, latitude: latitude, longitude: longitude)]
        }
        
        database.close()
        
        return locations
    }
    
    class func fetchLocationWithId(locationId: Int) -> Location? {
        let path = NSBundle.mainBundle().pathForResource("timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!database.open()) {
            return nil
        }
        
        let query = "SELECT l.Name, l.Latitude, l.Longitude FROM Location l WHERE l.LocationId = (?)"
        
        let resultSet = database.executeQuery(query, withArgumentsInArray: [locationId])
        var location: Location? = nil
        
        while (resultSet.next()) {
            let name = resultSet.stringForColumn("Name")
            let latitude = resultSet.doubleForColumn("Latitude")
            let longitude = resultSet.doubleForColumn("Longitude")
            location = Location(name: name, latitude: latitude, longitude: longitude)
        }
        
        database.close()
        
        return location

    }
    
    var name: String?
    var latitude: Double?
    var longitude: Double?

    var hashValue: Int {
        return "\(self.name)\(self.latitude)\(self.longitude)".hashValue
    }
    
    var weather: LocationWeather?
    var weatherFetchError: NSError?
    
    init(name: String?, latitude: Double?, longitude: Double?) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: -
func == (lhs: Location, rhs: Location) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
