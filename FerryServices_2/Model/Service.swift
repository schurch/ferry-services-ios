//
//  Service.swift
//  FerryServices_2
//
//  Created by Stefan Church on 12/12/20.
//  Copyright © 2020 Stefan Church. All rights reserved.
//

import Foundation

struct Service: Codable {
    static let servicesCacheLocation: URL = {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDirectory.appendingPathComponent("services.json")
    }()
    
    static let defaultServices: [Service] = {
        do {
            let data: Data = try {
                if FileManager.default.fileExists(atPath: servicesCacheLocation.path) {
                    return try Data(contentsOf: servicesCacheLocation)
                } else {
                    let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json")!
                    return try Data(contentsOf: URL(fileURLWithPath: defaultServicesFilePath))
                }
            }()
            
            return try APIDecoder.shared.decode([Service].self, from: data)
            
        } catch let error {
            fatalError("Unable to load default services: \(error)")
        }
    }()
    
    enum Status: Codable {
        case normal
        case disrupted
        case cancelled
        case unknown
        
        init(from decoder: Decoder) throws {
            let intValue = try decoder.singleValueContainer().decode(Int.self)
            switch intValue {
            case 0:
                self = .normal
            case 1:
                self = .disrupted
            case 2:
                self = .cancelled
            default:
                self = .unknown
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .normal: try container.encode(0)
            case .disrupted: try container.encode(1)
            case .cancelled: try container.encode(2)
            case .unknown: try container.encode(-99)
            }
        }
    }
    
    struct Location: Codable {
        struct Weather: Codable {
            let description: String
            let icon: String
            let temperatureCelsius: Int
            let windSpeedMph: Int
            let windDirection: Int
            let windDirectionCardinal: String
        }
        
        private enum CodingKeys: String, CodingKey {
            case name, latitude, longitude, weather
        }
        
        let name: String
        let latitude: Double
        let longitude: Double
        let weather: Weather?
    }
    
    let serviceId: Int
    let status: Status
    let area: String
    let route: String
    let disruptionReason: String?
    let lastUpdatedDate: Date? // Time updated by Calmac
    let updated: Date? // Time updated on server
    let additionalInfo: String?
    let locations: [Location]
}
