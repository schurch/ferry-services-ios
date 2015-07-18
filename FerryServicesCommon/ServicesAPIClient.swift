//
//  ServicesAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public class ServicesAPIClient {
    public static let sharedInstance = ServicesAPIClient()
    
    static let baseURL = NSURL(string: "http://stefanchurch.com:4567/")
    
    // MARK: - methods
    public func fetchFerryServicesWithCompletion(completion: (serviceStatuses: [ServiceStatus]?, error: NSError?) -> ()) {
        let url = NSURL(string: "services/", relativeToURL: ServicesAPIClient.baseURL)
        JSONRequester().requestWithURL(url!) { json, error in
            if error == nil {
                if let json = json {
                    var results = json.array?.map { json in ServiceStatus(data: json) }
                    results?.sort{ $0.sortOrder < $1.sortOrder }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(serviceStatuses: results, error: nil)
                    })
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(serviceStatuses: nil, error: error)
                })
            }
        }
    }
    
    public func fetchDisruptionDetailsForFerryServiceId(ferryServiceId: Int, completion: (disruptionsDetails: DisruptionDetails?, error: NSError?) -> ()) {
        let url = NSURL(string: "/services/\(ferryServiceId)", relativeToURL: ServicesAPIClient.baseURL)
        JSONRequester().requestWithURL(url!) { json, error in
            if error == nil {
                if let json = json {
                     let disruptionDetails = DisruptionDetails(data: json)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(disruptionsDetails: disruptionDetails, error: nil)
                    })
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(disruptionsDetails: nil, error: error)
                })
            }
        }
    }
}
