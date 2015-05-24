//
//  SCAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import FerryServicesCommon

class APIClient {
    
    private struct APICLientConstants {
        static let baseURL = "http://stefanchurch.com:4567"
    }

    // MARK: - type method
    class var clientErrorDomain: String {
        return "APICientErrorDomain"
    }

    class var sharedInstance: APIClient {
        struct Static {
            static let instance: APIClient = APIClient()
        }
        
        return Static.instance
    }
    
    // MARK: - properties
    private var requestManager: AFHTTPRequestOperationManager
    
    // MARK: - init
    init() {
        requestManager = AFHTTPRequestOperationManager(baseURL: NSURL(string: APICLientConstants.baseURL))
        requestManager.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer
    }
    
    // MARK: - methods
    func fetchFerryServicesWithCompletion(completion: (serviceStatuses: [ServiceStatus]?, error: NSError?) -> ()) {
        requestManager.GET("/services/" , parameters: nil, success: { operation, responseObject in
            
                let json = JSONValue(responseObject)
                if  (!json) {
                    completion(serviceStatuses: nil, error: NSError(domain:APIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                    return
                }
            
                var results = json.array?.map { json in ServiceStatus(data: json) }
                results?.sort{ $0.sortOrder < $1.sortOrder }
            
                completion(serviceStatuses: results, error: nil)
            
            }, failure: { operation, error in
                completion(serviceStatuses: nil, error: error)
            })
    }
    
    func fetchDisruptionDetailsForFerryServiceId(ferryServiceId: Int, completion: (disruptionsDetails: DisruptionDetails?, error: NSError?) -> ()) {
        
        requestManager.GET("/services/\(ferryServiceId)", parameters: nil, success:
            { operations, responseObject in
                
                let json = JSONValue(responseObject)
                
                var disruptionDetails: DisruptionDetails?
                if json {
                    disruptionDetails = DisruptionDetails(data: json)
                }
                else {
                    NSLog("There was an error fetching the data. Please try again.")
                    disruptionDetails = DisruptionDetails()
                }
                
                completion(disruptionsDetails: disruptionDetails, error: nil)
                
            }, failure: { operation, error in
                completion(disruptionsDetails: nil, error: error)
            })
    }
}
