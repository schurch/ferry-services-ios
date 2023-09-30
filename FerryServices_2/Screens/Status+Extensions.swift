//
//  Status+Extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/05/21.
//  Copyright © 2021 Stefan Church. All rights reserved.
//

import Foundation
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
