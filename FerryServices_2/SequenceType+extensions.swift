//
//  SequenceType+extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/06/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation

extension SequenceType {
    
    /// Categorises elements of self into a dictionary, with the keys given by keyFunc
    func categorise<U: Hashable>(@noescape keyFunc: Generator.Element -> U) -> [U: [Generator.Element]] {
        var dictionary: [U: [Generator.Element]] = [:]
        for element in self {
            let key = keyFunc(element)
            if case nil = dictionary[key]?.append(element) { dictionary[key] = [element] }
        }
        return dictionary
    }
    
}