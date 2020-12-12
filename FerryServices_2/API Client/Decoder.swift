//
//  Decoder.swift
//  FerryServices_2
//
//  Created by Stefan Church on 12/12/20.
//  Copyright © 2020 Stefan Church. All rights reserved.
//

import Foundation

struct APIDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { dateDecoder in
            let string = try dateDecoder.singleValueContainer().decode(String.self)
            let dateFormatter = ISO8601DateFormatter()
            
            dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
            if let date = dateFormatter.date(from: string) {
                return date
            }
            
            dateFormatter.formatOptions = [.withInternetDateTime]
            return dateFormatter.date(from: string)!
        }
        return decoder
    }()
}
