//
//  JSONRequester.swift
//  FerryServices_2
//
//  Created by Stefan Church on 17/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit
import SwiftyJSON
import Parse

class JSONRequester {
    static let errorDomain = "JSONRequesterErrorDomain"
    
    func requestWithURL(_ url: URL, completion:@escaping (_ json: JSON?, _ error: NSError?) -> ()) {
        PFNetworkActivityIndicatorManager.shared().incrementActivityCount()
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
            PFNetworkActivityIndicatorManager.shared().decrementActivityCount()
            
            guard error == nil else {
                completion(nil, error as NSError?)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: JSONRequester.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                return
            }
            
            let jsonDictionary: Any?
            
            do {
                jsonDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
                
                if let jsonDictionary = jsonDictionary {
                    let json = JSON(jsonDictionary)
                    completion(json, nil)
                }
                else {
                    completion(nil, NSError(domain: JSONRequester.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                }
            } catch let error as NSError {
                completion(nil, error)
            }
        }) 
        
        dataTask.resume()
    }
}
