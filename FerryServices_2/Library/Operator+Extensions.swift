//
//  Operator+Extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 18/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation

extension Service.ServiceOperator {
    var imageName: String? {
        switch self.id {
        case 1: return "calmac-logo"
        default: return nil
        }
    }
}
