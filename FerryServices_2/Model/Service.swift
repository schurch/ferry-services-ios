//
//  Service.swift
//  FerryServices_2
//
//  Created by Stefan Church on 12/12/20.
//  Copyright © 2020 Stefan Church. All rights reserved.
//

import Foundation

struct Service: Decodable {
    static let defaultServices: [Service] = {
        do {
            let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json")!
            let data = try Data(contentsOf: URL(fileURLWithPath: defaultServicesFilePath))
            let services = try APIDecoder.shared.decode([Service].self, from: data)
            return services.sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch let error {
            fatalError("Unable to load default services: \(error)")
        }
    }()
    
    enum Status: Decodable {
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
    }
    
    struct Location: Decodable {
        private enum CodingKeys: String, CodingKey {
            case name, latitude, longitude
        }
        
        let name: String
        let latitude: Double
        let longitude: Double
    }
    
    let serviceId: Int
    let sortOrder: Int
    let status: Status
    let area: String
    let route: String
    let disruptionReason: String?
    let lastUpdatedDate: Date? // Time updated by Calmac
    let updated: Date? // Time updated on server
    let additionalInfo: String?
    let locations: [Location]
}
