//
//  JSONRequester.swift
//  FerryServices_2
//
//  Created by Stefan Church on 17/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class JSONRequester {
    static let errorDomain = "JSONRequesterErrorDomain"
    
    func requestWithURL(url: NSURL, completion:(json: JSONValue?, error: NSError?) -> ()) {
        PFNetworkActivityIndicatorManager.sharedManager().incrementActivityCount()
        
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url) { data, response, error in
            if error != nil {
                completion(json: nil, error: error)
                return;
            }
            
            var jsonSerializationError: NSError?
            let jsonDictionary: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonSerializationError)
            
            if jsonSerializationError != nil {
                completion(json: nil, error: jsonSerializationError)
                return;
            }
            
            let json = JSONValue(jsonDictionary!)
            if  (!json) {
                completion(json: nil, error: NSError(domain: JSONRequester.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                return
            }
            
            completion(json: json, error: nil)
            
            PFNetworkActivityIndicatorManager.sharedManager().decrementActivityCount()
        }
        
        dataTask.resume()
    }
}
