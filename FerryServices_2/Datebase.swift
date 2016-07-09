//
//  Datebase.swift
//  FerryServices_2
//
//  Created by Stefan Church on 14/06/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import Interstellar
import SQLite

class Database {
    
    class func defaultDatabase() -> Database {
        return Database(filename: "timetables")
    }
    
    private var filename: String
    
    init(filename: String) {
        self.filename = filename
    }
    
    func fetchJourneys(serviceId serviceId: Int, date: NSDate) -> Signal<[Journey]> {
        return query(queryFile: "FetchJourneysQuery", values:
            date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            serviceId)
            .map(convertToJourneys)
    }
    
    func fetchStopPoints() -> Signal<[StopPoint]> {
        return query(queryFile: "FetchStopPointsQuery").map(convertToStopPoints)
    }
    
    func fetchStopPoints(serviceId serviceId: Int) -> Signal<[StopPoint]> {
        return query(queryFile: "FetchStopPointsForServiceQuery", values: serviceId, serviceId).map(convertToStopPoints)
    }
    
    private func convertToJourneys(statement: SQLite.Statement) -> [Journey] {
        return statement.flatMap { row in
            guard let from = row[0] as? String,
                to = row[1] as? String,
                departureHour = row[2] as? Int64,
                departureMinute = row[3] as? Int64,
                runningTimeSeconds = row[4] as? Int64 else {
                    
                    return nil
            }
            
            return Journey(from: from, to: to, departureHour: Int(departureHour), departureMinute: Int(departureMinute), runningTimeSeconds: Int(runningTimeSeconds))
        }
    }
    
    private func convertToStopPoints(statement: SQLite.Statement) -> [StopPoint] {
        return statement.flatMap { row in
            guard let stopPointId = row[0] as? String,
                name = row[1] as? String,
                latitude = row[2] as? Double,
                longitude = row[3] as? Double else {
                    
                    return nil
            }
            
            return StopPoint(stopPointId: stopPointId, name: name, latitude: latitude, longitude: longitude)
        }
    }
    
    private func query(queryFile queryFile: String, values: Binding?...) -> Signal<Statement> {
        return Signal(queryFile)
            .map { queryFile in
                let file = NSBundle.mainBundle().pathForResource(queryFile, ofType:"sql")!
                return try! NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding) as String
            }
            .map { (query: String) -> SQLite.Statement in
                let dbPath = NSBundle.mainBundle().pathForResource(self.filename, ofType:"sqlite")!
                let db = try! Connection(dbPath)
                return try! db.prepare(query).bind(values)
        }
    }
}