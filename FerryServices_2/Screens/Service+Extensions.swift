//
//  Service+Extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI

extension Service {
    var disruptionText: String {
        switch status {
        case .normal: return String(localized: "There are currently no disruptions with this service")
        case .disrupted: return String(localized: "There are disruptions with this service")
        case .cancelled: return String(localized: "Sailings have been cancelled for this service")
        case .unknown: return String(localized: "There was a problem fetching the service status")
        }
    }
    
    var anyScheduledDepartures: Bool {
        locations.contains(where: { $0.scheduledDepartures?.isEmpty == false })
    }
}
