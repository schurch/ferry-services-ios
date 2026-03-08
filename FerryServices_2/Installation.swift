//
//  Installation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/02/24.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import Foundation

struct Installation {
    static var id: UUID {
        AppPreferences.shared.installationID
    }
}
