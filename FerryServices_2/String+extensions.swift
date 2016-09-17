//
//  NSString+extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

extension String {
    
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
}
