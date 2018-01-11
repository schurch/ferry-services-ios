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
        case stopped
        case running
    }
    
    var state: SubscribedServicesFetcherState = .stopped
    
    // MARK: - 
    func fetchSubscribedServicesIdsWithCompletion(_ completion: @escaping (RequestResult<[Int]>) -> Void) {
        guard state == .stopped else {
            return
        }
        
        state = .running
        
        guard WCSession.default.isReachable else {
            let errorMessage = "Cannot communicate with your phone. Please check that bluetooth is enabled."
            let error = NSError(domain: "com.stefanchurch.ferryservices.watchkitapp.watchkitextension", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            
            completion(RequestResult.error(error: error))
            self.state = .stopped
            
            return
        }
        
        WCSession.default.sendMessage(["action": "fetchSubscribedServices"], replyHandler: { response in
            if let subscribedServiceIds = response["subscribedServiceIds"] as? [Int] {
                DispatchQueue.main.async(execute: {
                    completion(RequestResult.result(result: subscribedServiceIds))
                    self.state = .stopped
                })
            }
            else {
                let errorMessage = response["error"] as? String ?? "There was an error fetching subscribed services"
                let error = NSError(domain: "com.stefanchurch.ferryservices.watchkitapp.watchkitextension", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                
                DispatchQueue.main.async(execute: {
                    completion(RequestResult.error(error: error))
                    self.state = .stopped
                })
            }
            
        }, errorHandler: { error in
            DispatchQueue.main.async(execute: {
                completion(RequestResult.error(error: error as NSError))
                self.state = .stopped
            })
        })
    }
    
}
