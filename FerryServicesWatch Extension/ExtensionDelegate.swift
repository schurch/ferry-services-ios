//
//  ExtensionDelegate.swift
//  FerryServicesWatch Extension
//
//  Created by Stefan Church on 24/07/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import WatchConnectivity
import FerryServicesCommonWatch

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    var persistedRecentServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey("recentServiceIds") as? [Int]
    var recentServiceIds: [Int]?
    
    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            print("Sessions not supported")
            return
        }
        
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()
    }
    
    func applicationDidBecomeActive() {
        switch self.persistedRecentServiceIds {
        case let recentServiceIds? where recentServiceIds.count > 0:
            self.loadRecentServicesForIds(recentServiceIds)
        default:
            self.fetchRecentServicesFromPhoneWithCompletion { recentServiceIds in
                if let recentServiceIds = recentServiceIds where recentServiceIds.count > 0 {
                    NSUserDefaults.standardUserDefaults().setObject(recentServiceIds, forKey: "recentServiceIds")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    self.loadRecentServicesForIds(recentServiceIds)
                }
                else {
                    self.loadNoServices()
                }
            }
        }
    }
    
    private func fetchRecentServicesFromPhoneWithCompletion(completion: (recentServiceIds: [Int]?) -> ()) {
        guard WCSession.isSupported() else {
            print("Watch sessions not supported")
            return
        }
        
        WCSession.defaultSession().sendMessage(["action": "sendRecentServiceIds"], replyHandler: { response in
            if let recentServiceIds = response["recentServiceIds"] as? [Int] {
                completion(recentServiceIds: recentServiceIds)
            }
            else {
                completion(recentServiceIds: nil)
            }
        }, errorHandler: { error in
                completion(recentServiceIds: nil)
        })
    }
    
    private func loadRecentServicesForIds(recentServiceIds: [Int]) {
        let controllers = Array(count: recentServiceIds.count, repeatedValue: "serviceDetail")
        WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: recentServiceIds)
    }
    
    private func loadNoServices() {
        WKInterfaceController.reloadRootControllersWithNames(["noServices"], contexts: nil)
    }
}

extension ExtensionDelegate: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let recentServiceIds = applicationContext["recentServiceIds"] as? [Int] {
            NSUserDefaults.standardUserDefaults().setObject(recentServiceIds, forKey: "recentServiceIds")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
}
