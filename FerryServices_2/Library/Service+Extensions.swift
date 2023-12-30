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
        case .normal: return NSLocalizedString("There are currently no disruptions with this service", comment: "")
        case .disrupted: return NSLocalizedString("There are disruptions with this service", comment: "")
        case .cancelled: return NSLocalizedString("Sailings have been cancelled for this service", comment: "")
        case .unknown: return NSLocalizedString("There was a problem fetching the service status", comment: "")
        }
    }
}
