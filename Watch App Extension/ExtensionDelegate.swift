//
//  ExtensionDelegate.swift
//  Watch App Extension
//
//  Created by Stefan Church on 7/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import WatchConnectivity

let subscribedServiceIdsUserDefaultsKey = "com.ferryservices.userdefaultkeys.subscribedservices"

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            print("Sessions not supported")
            return
        }
        
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()
        
        reloadServices()
    }

    func applicationDidBecomeActive() {
        
    }

    func applicationWillResignActive() {
        
    }
    
    private func reloadServices() {
        if let currentServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey(subscribedServiceIdsUserDefaultsKey) as? [Int] {
            if currentServiceIds.count > 0 {
                WKInterfaceController.reloadRootControllersWithNames(Array(count: currentServiceIds.count, repeatedValue: "ServiceDetail"), contexts: currentServiceIds)
            }
            else {
                WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
            }
        }
        else {
            WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
        }
    }

}

extension ExtensionDelegate: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let subscribedServiceIds = applicationContext["subscribedServiceIds"] as? [Int] {
            let sortedServices = subscribedServiceIds.sort()
            NSUserDefaults.standardUserDefaults().setObject(sortedServices, forKey: subscribedServiceIdsUserDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            reloadServices()
        }
    }
    
}

