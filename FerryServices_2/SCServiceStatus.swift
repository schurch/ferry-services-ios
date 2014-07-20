//
//  SCServiceStatus.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class SCServiceStatus: NSObject {
    
    enum SCDisriptionStatus: Int {
        case Unknown = -99
        case Normal = -1
        case SailingsAffected = 1
        case SailingsCancelled = 2
    }
    
    var area: String?
    var disruptionStatus: SCDisriptionStatus!
    var ferryProvider: String?
    var route: String?
    var routeId: Int?
    var sortOrder: Int?
    
    init(data: Dictionary<String, AnyObject>) {
        
        area = SCServiceStatus.valueForDictionaryKey("Area", dictionary: data)
        ferryProvider = SCServiceStatus.valueForDictionaryKey("provider", dictionary: data)
        route = SCServiceStatus.valueForDictionaryKey("Route", dictionary: data)
        routeId = SCServiceStatus.valueForDictionaryKey("RouteId", dictionary: data)
        sortOrder = SCServiceStatus.valueForDictionaryKey("SortOrder", dictionary: data)
        
        if let status: AnyObject = data["DisruptionStatus"] {
            var disruptionStatus = status as? Int
            if let statusNumber = disruptionStatus {
                self.disruptionStatus = SCDisriptionStatus.fromRaw(statusNumber)
            }
        }
        
//        if let area: AnyObject = data["Area"] {
//            self.area = area as? String
//        }
        
//        if let route: AnyObject = data["Route"] {
//            self.route = route as? String
//        }
//        
//        if let routeId: AnyObject = data["RouteID"] {
//            self.routeId = routeId as? Int
//        }
//        
//        if let sortOrder: AnyObject = data["SortOrder"] {
//            self.sortOrder = sortOrder as? Int
//        }
        
    }
    
    class func valueForDictionaryKey<T>(key :String, dictionary :Dictionary<String, AnyObject>) -> T? {
        if let value: AnyObject = dictionary[key] {
            return value as? T
        }
        
        return nil
    }
   
}
