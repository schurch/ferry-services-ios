//
//  Vessel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Vessel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    enum Status: Int {
        case underwayUsingEngine = 0
        case atAnchor = 1
        case notUnderCommand = 2
        case restrictedManeuverability = 3
        case constrainedByHerDraught = 4
        case moored = 5
        case aground = 6
        case engagedInFishing = 7
        case underwaySailing = 8
        case reserved1 = 9
        case reserved2 = 10
        case powerDrivenVesselTowingAstern = 11
        case powerDrivenVesselPushingAhead = 12
        case reserved3 = 13
        case aisSart = 14
        case undefined = 15
        
        var description: String {
            switch self {
            case .underwayUsingEngine:
                return "Underway"
            case .atAnchor:
                return "Anchored"
            case .notUnderCommand:
                return "Not under command"
            case .restrictedManeuverability:
                return "Restriced maneuverability"
            case .constrainedByHerDraught:
                return "Constrained by her draft"
            case .moored:
                return "Moored"
            case .aground:
                return "Aground"
            case .engagedInFishing:
                return "Engaged in fishing"
            case .underwaySailing:
                return "Underway"
            default:
                return "Unknown status"
            }
        }
    }
    
    var mmsi: Int
    var updated: Date?
    var locationUpdated: Date?
    var name: String
    var latitude: Double
    var longitude: Double
    var course: Double?
    var speed: Double?
    var status: Status?
    
    var isUnderway: Bool {
        return status == .underwayUsingEngine || status == .underwaySailing
    }
    
    init(data: [String: AnyObject]) {
        let json = JSON(data)
        
        mmsi = json["mmsi"].intValue
        
        if let updatedDate = json["updated"].string {
            updated = Vessel.dateFormatter.date(from: updatedDate)
        }
        
        if let locationUpdatedDate = json["location_updated"].string {
            locationUpdated = Vessel.dateFormatter.date(from: locationUpdatedDate)
        }
        
        name = json["name"].stringValue
        latitude = json["latitude"].doubleValue
        longitude = json["longitude"].doubleValue
        course = json["course"].double
        
        if let speedValue = json["speed"].double {
            speed = speedValue / 10.0
        }
        
        if let rawStatus = json["status"].int {
            status = Status(rawValue: rawStatus)
        }
    }
}

extension Vessel {
    var statusDescription: String {
        guard let status = status, let locationUpdated = locationUpdated else { return "Unknown status" }
        
        if let speed = speed, speed <= 1.0 && isUnderway {
            return "Stopped • \(locationUpdated.relativeTimeSinceNowText())"
        }
        
        return "\(status.description) • \(locationUpdated.relativeTimeSinceNowText())"
    }
}

extension Vessel: Hashable {
    var hashValue: Int {
        return mmsi
    }
}

func == (lhs: Vessel, rhs: Vessel) -> Bool {
    return lhs.mmsi == rhs.mmsi
}
