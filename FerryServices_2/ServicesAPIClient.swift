//
//  ServicesAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

class ServicesAPIClient {
    static let sharedInstance = ServicesAPIClient()

    #if DEBUG
    static let baseURL = NSURL(string: "http://test.scottishferryapp.com")
    #else
    static let baseURL = URL(string: "http://www.scottishferryapp.com")
    #endif
    
    
    // MARK: - methods
    func fetchFerryServicesWithCompletion(_ completion: @escaping (_ serviceStatuses: [ServiceStatus]?, _ error: NSError?) -> ()) {
        let url = URL(string: "services/", relativeTo: ServicesAPIClient.baseURL as URL?)
        JSONRequester().requestWithURL(url!) { json, error in
            if error == nil {
                if let json = json {
                    var results = json.array?.map { json in ServiceStatus(data: json) }
                    results?.sort{ $0.sortOrder! < $1.sortOrder! }
                    
                    DispatchQueue.main.async(execute: {
                        completion(results, nil)
                    })
                }
            }
            else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
    
    func fetchDisruptionDetailsForFerryServiceId(_ ferryServiceId: Int, completion: @escaping (_ disruptionsDetails: DisruptionDetails?, _ error: NSError?) -> ()) {
        let url = URL(string: "/services/\(ferryServiceId)", relativeTo: ServicesAPIClient.baseURL as URL?)
        JSONRequester().requestWithURL(url!) { json, error in
            if error == nil {
                if let json = json {
                     let disruptionDetails = DisruptionDetails(data: json)
                    
                    DispatchQueue.main.async(execute: {
                        completion(disruptionDetails, nil)
                    })
                }
            }
            else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        }
    }
}
