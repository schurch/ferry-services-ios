//
//  JSONRequester.swift
//  FerryServices_2
//
//  Created by Stefan Church on 17/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit
import SwiftyJSON

class JSONRequester {
    static let errorDomain = "JSONRequesterErrorDomain"
    
    func requestWithURL(url: NSURL, completion:(json: JSON?, error: NSError?) -> ()) {
        PFNetworkActivityIndicatorManager.sharedManager().incrementActivityCount()
        
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url) { data, response, error in
            PFNetworkActivityIndicatorManager.sharedManager().decrementActivityCount()
            
            guard error == nil else {
                completion(json: nil, error: error)
                return
            }
            
            guard let data = data else {
                completion(json: nil, error: NSError(domain: JSONRequester.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                return
            }
            
            let jsonDictionary: AnyObject?
            
            do {
                jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
                
                if let jsonDictionary = jsonDictionary {
                    let json = JSON(jsonDictionary)
                    completion(json: json, error: nil)
                }
                else {
                    completion(json: nil, error: NSError(domain: JSONRequester.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                }
            } catch let error as NSError {
                completion(json: nil, error: error)
            }
        }
        
        dataTask.resume()
    }
}
