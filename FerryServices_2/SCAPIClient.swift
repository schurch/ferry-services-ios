//
//  SCAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class SCAPIClient: NSObject {
    
    struct SCAPICLientConstants {
        static let baseURL = "http://ws.sitekit.net"
    }
    
    // MARK: type method
    class var sharedInstance: SCAPIClient {
        struct Static {
            static let instance: SCAPIClient = SCAPIClient()
        }
        
        return Static.instance
    }
    
    // MARK: properties
    var requestManager: AFHTTPRequestOperationManager
    
    // MARK: init
    init() {
        requestManager = AFHTTPRequestOperationManager(baseURL: NSURL.URLWithString(SCAPICLientConstants.baseURL))
        requestManager.responseSerializer = AFJSONResponseSerializer()
        requestManager.requestSerializer.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        requestManager.requestSerializer.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D167 (350921184)", forHTTPHeaderField: "User-Agent")
        
        #if DEBUG
            requestManager.responseSerializer.acceptableContentTypes = NSSet("text/plain", "application/json", 2)
        #endif
        
        super.init()
    }
    
    // MARK: methods
    func fetchFerryServicesWithCompletion(completion: (serviceStatuses: [SCServiceStatus]?, error: NSError?) -> ()) {
        requestManager.GET("/ServiceDisruptions/servicestatusfrontV3.asmx/ListServiceStatuses_JSON" , parameters: nil, success: { operation, responseObject in
            
                let reponseData = responseObject as Dictionary<String, AnyObject>
                let statuses: [Dictionary<String, AnyObject>] = reponseData["ServiceStatuses"]! as [Dictionary<String, AnyObject>]
            
                var results = [SCServiceStatus]()
                for statusData in statuses {
                    let serviceStatus = SCServiceStatus(data: statusData)
                    results += serviceStatus
                }
            
                completion(serviceStatuses: results, error: nil)
            
            }, failure: { operation, error in
                completion(serviceStatuses: nil, error: error)
            })
    }
   
}
