//
//  JSONRequester.swift
//  FerryServices_2
//
//  Created by Stefan Church on 17/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

public class JSONRequester {
    public static let requestStartedNotification = "com.stefanchurch.ferryservices.requestStartedNotification"
    public static let requestFinishedNotification = "com.stefanchurch.ferryservices.requestFinishedNotification"
    
    static let errorDomain = "JSONRequesterErrorDomain"
    
    func requestWithURL(url: NSURL, completion:(json: JSONValue?, error: NSError?) -> ()) {
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(JSONRequester.requestStartedNotification, object: self)
        })
        
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url) { data, response, error in
            if error != nil {
                completion(json: nil, error: error)
                return;
            }
            
            var jsonSerializationError: NSError?
            let jsonDictionary: AnyObject?
            do {
                jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
            } catch let error as NSError {
                jsonSerializationError = error
                jsonDictionary = nil
            } catch {
                fatalError()
            }
            
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
            
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(JSONRequester.requestFinishedNotification, object: self)
            });
        }
        
        dataTask.resume()
    }
}
