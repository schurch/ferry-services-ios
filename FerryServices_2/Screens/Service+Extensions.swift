//
//  Service+Extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI

extension Service.Status {
    var statusColor: Color {
        switch self {
        case .unknown: return Color("Grey")
        case .normal: return Color("Green")
        case .disrupted: return Color("Amber")
        case .cancelled: return Color("Red")
        }
    }
}
