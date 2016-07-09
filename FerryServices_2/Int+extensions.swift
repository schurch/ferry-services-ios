//
//  Int+extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 20/06/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

extension Int {
    func padWithZero() -> String {
        return self < 10 ? "0\(self)" : String(self)
    }
}