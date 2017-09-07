//
//  MultiJourneyDeparture.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/08/17.
//  Copyright © 2017 Stefan Church. All rights reserved.
//

import Foundation

struct MultiJourneyDeparture {
    
    var routeSectionId: String
    var fromCode: String
    var from: String
    var toCode: String
    var to: String
    var departureHour: Int
    var departureMinute: Int
    var runTime: Int
    var waitTime: Int?
    var order: Int
    var note: String?
    
}

extension MultiJourneyDeparture: DBResultInitializable {
    
    init?(result: FMResultSet) {
        guard let routeSectionId = result.string(forColumn: "RouteSectionId") else { return nil }
        guard let fromCode = result.string(forColumn: "FromCode") else { return nil }
        guard let from = result.string(forColumn: "From") else { return nil }
        guard let toCode = result.string(forColumn: "ToCode") else { return nil }
        guard let to = result.string(forColumn: "To") else { return nil }
        guard let runTime = result.string(forColumn: "RunTime") else { return nil }
        guard let runTimeValue = Int(runTime.digits) else { return nil }
    
        let depatureHour = result.int(forColumn: "Hour")
        let depatureMinute = result.int(forColumn: "Minute")
        let order = result.int(forColumn: "Order")
        
        let waitTimeValue: Int?
        if let waitTime = result.string(forColumn: "WaitTime") {
            waitTimeValue = Int(waitTime.digits)
        }
        else {
            waitTimeValue = nil
        }
        
        let note = result.string(forColumn: "note")
        
        self = MultiJourneyDeparture(routeSectionId: routeSectionId, fromCode: fromCode, from: from, toCode: toCode, to: to, departureHour: Int(depatureHour), departureMinute: Int(depatureMinute), runTime: runTimeValue, waitTime: waitTimeValue, order: Int(order), note: note)
    }
    
}
