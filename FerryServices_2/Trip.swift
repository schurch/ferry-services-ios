//
//  SCTrip.swift
//  FerryServices_2
//
//  Created by Stefan Church on 27/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

class Trip {
    
    fileprivate struct formatters {
        fileprivate static let weekdayFormatter :DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter
        }()
    }
    
    class func areTripsAvailableForRouteId(_ routeId: Int, onOrAfterDate: Date) -> Bool {
        let path = Bundle.main.path(forResource: "timetables", ofType: "sqlite")
        if path == nil {
            return false
        }
        
        let database = FMDatabase(path: path)
        if database == nil {
            return false
        }
        
        if (!(database?.open())!) {
            return false
        }
        
        let strippedDate = Date.stripTimeComponentsFromDate(onOrAfterDate)
        
        let weekday = self.formatters.weekdayFormatter.string(from: strippedDate)
        
        var query = "SELECT COUNT(*)\n"
        query += "FROM CalendarTrip ct,\n"
        query += "(SELECT c.CalendarId\n"
        query += "FROM Calendar c\n"
        query += "WHERE c.EndDate >= (?)\n"
        query += "AND c.\(weekday) = 1\n"
        query += "AND c.CalendarId NOT IN (SELECT e.CalendarId\n"
        query += "FROM Exclusion e\n"
        query += "WHERE e.ExclusionDate = (?))\n"
        query += ") as c\n"
        query += "INNER JOIN Trip t ON t.TripId = ct.TripId\n"
        query += "INNER JOIN Route r on r.RouteId = t.RouteId\n"
        query += "WHERE ct.CalendarId = c.CalendarId\n"
        query += "AND r.routeId = (?)\n"
        query += "ORDER BY DepartureHour, DepartureMinute"
        
        let dateAsEpoc = strippedDate.timeIntervalSince1970
        
        var count = 0
        if let resultSet = database?.executeQuery(query, withArgumentsIn: [dateAsEpoc, dateAsEpoc, routeId]) {
            if resultSet.next() {
                count = Int(resultSet.int(forColumnIndex: 0))
            }
        }

        database?.close()
        
        return count > 0
    }
    
    class func fetchTripsForRouteId(_ routeId: Int, date: Date) -> [Trip]? {
        let path = Bundle.main.path(forResource: "timetables", ofType: "sqlite")
        let database = FMDatabase(path: path)
        
        if (!(database?.open())!) {
            return nil
        }
        
        let weekday = self.formatters.weekdayFormatter.string(from: date)
        
        var query = "SELECT t.Notes as Notes, t.DepartureHour as DepartureHour, t.DepartureMinute as DepartureMinute,"
        query += "t.ArrivalHour as ArrivalHour, t.ArrivalMinute as ArrivalMinute\n"
        query += "FROM CalendarTrip ct,\n"
        query += "(SELECT c.CalendarId\n"
        query += "FROM Calendar c\n"
        query += "WHERE c.StartDate <= (?)\n"
        query += "AND c.EndDate >= (?)\n"
        query += "AND c.\(weekday) = 1\n"
        query += "AND c.CalendarId NOT IN (SELECT e.CalendarId\n"
        query += "FROM Exclusion e\n"
        query += "WHERE e.ExclusionDate = (?))\n"
        query += ") as c\n"
        query += "INNER JOIN Trip t ON t.TripId = ct.TripId\n"
        query += "INNER JOIN Route r on r.RouteId = t.RouteId\n"
        query += "WHERE ct.CalendarId = c.CalendarId\n"
        query += "AND r.routeId = (?)\n"
        query += "ORDER BY DepartureHour, DepartureMinute"
        
        let dateAsEpoc = date.timeIntervalSince1970
        
        let resultSet = database?.executeQuery(query, withArgumentsIn: [dateAsEpoc, dateAsEpoc, dateAsEpoc, routeId])
        
        var trips = [Trip]()
        while (resultSet?.next())! {
            let departureHour = resultSet?.double(forColumn: "DepartureHour")
            let departureMinute = resultSet?.double(forColumn: "DepartureMinute")
            let arrivalHour = resultSet?.double(forColumn: "ArrivalHour")
            let arrivalMinute = resultSet?.double(forColumn: "ArrivalMinute")
            let notes = resultSet?.string(forColumn: "Notes")
            
            let trip = Trip(departureHour: departureHour!, departureMinute: departureMinute!, arrivalHour: arrivalHour!, arrivalMinute: arrivalMinute!, notes: notes, routeId: routeId)
            trips += [trip]
        }
        
        database?.close()
        
        return trips
    }
    
    var departureHour: Double
    var departureMinute: Double
    var arrivalHour: Double
    var arrivalMinute: Double
    var notes: String?
    var routeId: Int
    
    var deparuteTime: String {
        let departureHour = self.padWithZero(self.departureHour)
        let departureMinute = self.padWithZero(self.departureMinute)
        return "\(departureHour):\(departureMinute)"
    }
    
    var arrivalTime: String {
        let arrivalHour = self.padWithZero(self.arrivalHour)
        let arrivalMinute = self.padWithZero(self.arrivalMinute)
        return "\(arrivalHour):\(arrivalMinute)"
    }
    
    init(departureHour: Double, departureMinute: Double, arrivalHour: Double, arrivalMinute: Double, notes: String?, routeId: Int) {
        self.departureHour = departureHour
        self.departureMinute = departureMinute
        self.arrivalHour = arrivalHour
        self.arrivalMinute = arrivalMinute
        self.notes = notes
        self.routeId = routeId
    }
    
    fileprivate func padWithZero(_ number: Double) -> String {
        return number < 10 ? "0\(Int(number))" : "\(Int(number))"
    }
    
}
