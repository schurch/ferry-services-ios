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
        case .unknown: return .colorGrey
        case .normal: return .colorGreen
        case .disrupted: return .colorAmber
        case .cancelled: return .colorRed
        }
    }
}
