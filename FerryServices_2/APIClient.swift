//
//  SCAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

public class APIClient {
    
    public class var clientErrorDomain: String {
        return "APICientErrorDomain"
    }
    
    private struct APICLientConstants {
        static let baseURL = "http://ws.sitekit.net"
    }
    
    // MARK: - type method
    public class var sharedInstance: APIClient {
        struct Static {
            static let instance: APIClient = APIClient()
        }
        
        return Static.instance
    }
    
    // MARK: - properties
    private var requestManager: AFHTTPRequestOperationManager
    
    // MARK: - init
    init() {
        requestManager = AFHTTPRequestOperationManager(baseURL: NSURL.URLWithString(APICLientConstants.baseURL))
        requestManager.responseSerializer = AFJSONResponseSerializer()
        requestManager.requestSerializer.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        requestManager.requestSerializer.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D167 (350921184)", forHTTPHeaderField: "User-Agent")
        
        #if DEBUG
            requestManager.responseSerializer.acceptableContentTypes = NSSet("text/plain", "application/json", 2)
        #endif
    }
    
    // MARK: - methods
    public func fetchFerryServicesWithCompletion(completion: (serviceStatuses: [ServiceStatus]?, error: NSError?) -> ()) {
        requestManager.GET("/ServiceDisruptions/servicestatusfrontV3.asmx/ListServiceStatuses_JSON" , parameters: nil, success: { operation, responseObject in
            
                let json = JSONValue(responseObject)
                if  (!json) {
                    completion(serviceStatuses: nil, error: NSError(domain:APIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                    return
                }
            
                if (json["Success"].integer? != 1) {
                    completion(serviceStatuses: nil, error: NSError(domain:APIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                    return
                }
            
                let results = json["ServiceStatuses"].array?.map{ json in ServiceStatus(data: json) }
            
                completion(serviceStatuses: results, error: nil)
            
            }, failure: { operation, error in
                completion(serviceStatuses: nil, error: error)
            })
    }
    
    public func fetchDisruptionDetailsForFerryServiceId(ferryServiceId: Int, completion: (disruptionsDetails: DisruptionDetails?, routeDetails: RouteDetails?, error: NSError?) -> ()) {
        
        requestManager.GET("/ServiceDisruptions/servicestatusfrontV3.asmx/ListRouteDisruptions_JSON", parameters: ["routeID": ferryServiceId], success:
            { operations, responseObject in
                
                let json = JSONValue(responseObject)
                if (!json) {
                    completion(disruptionsDetails: nil, routeDetails: nil, error: NSError(domain:APIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                    return
                }
                
                var disruptionDetails: DisruptionDetails?
                if let disruptionData = json["RouteDisruption"].object {
                    disruptionDetails = DisruptionDetails(data: disruptionData)
                }
                else {
                    disruptionDetails = DisruptionDetails()
                }

                var routeDetails: RouteDetails?
                if let routeDetailsData = json["RouteDetail"].object {
                    routeDetails = RouteDetails(data: routeDetailsData)
                }
                
                completion(disruptionsDetails: disruptionDetails, routeDetails: routeDetails, error: nil)
                
            }, failure: { operation, error in
                completion(disruptionsDetails: nil, routeDetails: nil, error: error)
            })
    }
}
