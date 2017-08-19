//
//  Departures.swift
//  FerryServices_2
//
//  Created by Stefan Church on 5/08/17.
//  Copyright © 2017 Stefan Church. All rights reserved.
//

import Foundation
import RxSwift

protocol DBResultInitializable {
    init?(result: FMResultSet)
}

class Departures {
    
    static let timeZone = TimeZone(identifier: "UTC")
    
    enum QueryType: String {
        case standard = "standard_departures"
        case multi = "multi_journey_departures"
    }
    
    private static var dayOfWeekFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.timeZone = Departures.timeZone
        return dateFormatter
    }
    
    private static func departureSql(forDate date: Date, queryType: QueryType) -> String {
        let file = Bundle.main.path(forResource: queryType.rawValue, ofType:"sql")!
        let query = try! String.init(contentsOfFile: file)
        let dayOfWeekString = Departures.dayOfWeekFormatter.string(from: date)
        
        return query.replacingOccurrences(of: "{{dayOfWeek}}", with: dayOfWeekString)
    }
    
    func fetchDepartures(date: Date, from: String, to: String) -> [Departure] {
        let singleJourneyDepartures = fetchSingleJourneyDepartures(date: date, from: from, to: to)
        let multiJourneyDepartures = fetchMultiJourneyDepartures(date: date, from: from, to: to)
        let allDepatures = (singleJourneyDepartures + multiJourneyDepartures).sorted()
        return allDepatures
    }
    
    func fetchSingleJourneyDepartures(date: Date, from: String, to: String) -> [Departure] {
        let query = Departures.departureSql(forDate: date, queryType: .standard)
        let departures: [Departure] = fetchResults(query: query, values: [date, date, date, date, from, to, from, to, date, date])
        
        return departures
    }
    
    private func fetchMultiJourneyDepartures(date: Date, from: String, to: String) -> [Departure] {
        let query = Departures.departureSql(forDate: date, queryType: .multi)
        let multiJourneys: [MultiJourneyDeparture] = fetchResults(query: query, values: [from, to, date, date, date, date, date, date])
        
        let groupedJourneys = multiJourneys.group(by: { $0.routeSectionId })
        return groupedJourneys.flatMap { journeys in
            guard let actualJourney = journeys.first(where: { $0.fromCode == from && $0.toCode == to }) else { return nil }
            
            // Work out the total time for all the prior journeys to the one we're interested in on the route
            let ordered = journeys.sorted(by: { $0.order < $1.order })
            let priorJourneys = ordered.prefix(while: { $0.fromCode != from })
            let priorSeconds = priorJourneys.reduce(0) { sum, current in
                return sum + current.runTime + (current.waitTime ?? 0)
            }
            
            let totalSeconds = priorSeconds + (actualJourney.waitTime ?? 0)
            
            // The original departure time at the start of the route
            var originalDeparture = Calendar.current.dateComponents([.year, .month, .day], from: date)
            originalDeparture.hour = ordered.first?.departureHour
            originalDeparture.minute = ordered.first?.departureMinute
            let departureDate = Calendar.current.date(from: originalDeparture)!
            
            // Time taken for all prior journeys on the route
            var addition = DateComponents()
            addition.second = totalSeconds
            
            // Actual departure = original departure on route + time taken for all prior journeys
            let actualJourneyDeparture = Calendar.current.date(byAdding: addition, to: departureDate)!
            let departureComponents = Calendar.current.dateComponents([.hour, .minute], from: actualJourneyDeparture)
            
            return Departure(from: actualJourney.from, to: actualJourney.to, departureHour: departureComponents.hour!, departureMinute: departureComponents.minute!, runTime: actualJourney.runTime)
        }
    }
    
    private func fetchResults<T: DBResultInitializable>(query: String, values: [Any]) -> [T] {
        let dbPath = Bundle.main.path(forResource: "departures", ofType:"sqlite")!
        guard let database = FMDatabase(path: dbPath) else { return [] }
        guard database.open() else { return [] }
        
        defer {
            database.close()
        }
        
        var results = [T]()
        
        do {
            let result = try database.executeQuery(query, values: values)
            while result.next() {
                if let entry = T(result: result) {
                    results.append(entry)
                }
            }
        }
        catch (let error) {
            print("Error: \(error)")
        }
        
        return results
    }
}

extension Sequence {
    
    func group<GroupingType: Hashable>(by key: (Iterator.Element) -> GroupingType) -> [[Iterator.Element]] {
        var groups: [GroupingType: [Iterator.Element]] = [:]
        
        forEach { element in
            let key = key(element)
            if let values = groups[key] {
                groups[key] = values + [element]
            }
            else {
                groups[key] = [element]
            }
        }
        
        return groups.values.map { $0 }
    }
    
}
