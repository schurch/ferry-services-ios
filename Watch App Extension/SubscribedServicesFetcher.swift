//
//  SubscribedServicesFetcher.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import Foundation
import WatchConnectivity

internal class SubscribedServicesFetcher {
    
    enum SubscribedServicesFetcherState: Int {
        case Stopped
        case Running
    }
    
    var state: SubscribedServicesFetcherState = .Stopped
    
    // MARK: - 
    func fetchSubscribedServicesIdsWithCompletion(completion: RequestResult<[Int]> -> Void) {
        guard state == .Stopped else {
            return
        }
        
        state = .Running
        
        guard WCSession.defaultSession().reachable else {
            let errorMessage = "Cannot communicate with your phone. Please check that bluetooth is enabled."
            let error = NSError(domain: "com.stefanchurch.ferryservices.watchkitapp.watchkitextension", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            
            completion(RequestResult.Error(error: error))
            self.state = .Stopped
            
            return
        }
        
        WCSession.defaultSession().sendMessage(["action": "fetchSubscribedServices"], replyHandler: { response in
            if let subscribedServiceIds = response["subscribedServiceIds"] as? [Int] {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(RequestResult.Result(result: subscribedServiceIds))
                    self.state = .Stopped
                })
            }
            else {
                let errorMessage = response["error"] as? String ?? "There was an error fetching subscribed services"
                let error = NSError(domain: "com.stefanchurch.ferryservices.watchkitapp.watchkitextension", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                
                dispatch_async(dispatch_get_main_queue(), {
                    completion(RequestResult.Error(error: error))
                    self.state = .Stopped
                })
            }
            
        }, errorHandler: { error in
            dispatch_async(dispatch_get_main_queue(), {
                completion(RequestResult.Error(error: error))
                self.state = .Stopped
            })
        })
    }
    
}
