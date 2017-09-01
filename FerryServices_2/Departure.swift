//
//  Departure.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/08/17.
//  Copyright © 2017 Stefan Church. All rights reserved.
//

import Foundation

struct Departure {
    
    var from: String
    var to: String
    var departureHour: Int
    var departureMinute: Int
    var runTime: Int
    var order: Int?
    
    var departureTime: String {
        return "\(departureHour.padWithZero()):\(departureMinute.padWithZero())"
    }
    
    func arrivalTime(withDate date: Date) -> String {
        var departure = Calendar.current.dateComponents([.year, .month, .day], from: date)
        departure.hour = departureHour
        departure.minute = departureMinute
        let departureDate = Calendar.current.date(from: departure)!
        
        var addition = DateComponents()
        addition.second = runTime
        
        let arrivalDate = Calendar.current.date(byAdding: addition, to: departureDate)!
        let arrivalComponents = Calendar.current.dateComponents([.hour, .minute], from: arrivalDate)
        
        return "\(arrivalComponents.hour!.padWithZero()):\(arrivalComponents.minute!.padWithZero())"
    }
    
}

extension Int {
    
    func padWithZero() -> String {
        return self < 10 ? "0\(self)" : String(self)
    }
    
}

extension Departure: DBResultInitializable {
    
    init?(result: FMResultSet) {
        guard let from = result.string(forColumn: "From") else { return nil }
        guard let to = result.string(forColumn: "To") else { return nil }
        guard let runTime = result.string(forColumn: "RunTime") else { return nil }
        guard let runTimeValue = Int(runTime.digits) else { return nil }
        
        let depatureHour = result.int(forColumn: "Hour")
        let depatureMinute = result.int(forColumn: "Minute")
        
        self = Departure(from: from, to: to, departureHour: Int(depatureHour), departureMinute: Int(depatureMinute), runTime: runTimeValue, order: nil)
    }
    
}
