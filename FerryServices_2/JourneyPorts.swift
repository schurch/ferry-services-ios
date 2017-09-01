//
//  Ports.swift
//  FerryServices_2
//
//  Created by Stefan Church on 29/08/17.
//  Copyright © 2017 Stefan Church. All rights reserved.
//

import Foundation

struct JourneyPorts {
    
    var from: String
    var to: String
    
}

extension JourneyPorts: DBResultInitializable {
    
    init?(result: FMResultSet) {
        guard let from = result.string(forColumn: "From") else { return nil }
        guard let to = result.string(forColumn: "To") else { return nil }
        
        self = JourneyPorts(from: from, to: to)
    }
    
}
