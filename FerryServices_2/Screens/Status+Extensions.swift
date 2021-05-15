//
//  Status+Extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/05/21.
//  Copyright © 2021 Stefan Church. All rights reserved.
//

import Foundation
import UIKit

extension Service.Status {
    var color: UIColor {
        switch self {
        case .normal:
            return UIColor(named: "Green")!
        case .disrupted:
            return UIColor(named: "Amber")!
        case .cancelled:
            return UIColor(named: "Red")!
        case .unknown:
            return UIColor(named: "Grey")!
        }
    }
}
