//
//  Installation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/02/24.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import Foundation

struct Installation {
    static let id: UUID = {
        let key = "installationID"
        
        if let id = UserDefaults.standard.string(forKey: key) {
            return UUID(uuidString: id)!
        } else {
            let id = UUID()
            UserDefaults.standard.set(id.uuidString, forKey: key)
            return id
        }
    }()
}
