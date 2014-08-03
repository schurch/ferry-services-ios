//
//  DisruptionDetails.swift
//  FerryServices_2
//
//  Created by Stefan Church on 02/08/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public class DisruptionDetails {
 
    public enum DisruptionDetailsStatus: Int {
        case Normal = 0
        case SailingsAffected = 1
        case SailingsCancelled = 2
        case Information = -1
    }
    
    public var addedBy: String?
    public var addedDate: NSDate?
    public var details: String?
    public var disruptionEndDate: NSDate?
    public var lastUpdatedBy: String?
    public var reason: String?
    public var updatedDate: NSDate?
    public var disruptionStatus: DisruptionDetailsStatus?
    
    init(data: JSONValue) {
        
    }
}