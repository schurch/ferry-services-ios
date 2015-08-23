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
    
    var recentServices = NSUserDefaults.standardUserDefaults().arrayForKey("recentServiceIds") as? [Int]
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        
        switch self.recentServices {
        case let recentServiceIds?:
            let controllers = Array(count: recentServiceIds.count, repeatedValue: "serviceDetail")
            WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: recentServiceIds)
        case nil:
            WKInterfaceController.reloadRootControllersWithNames(["noServices"], contexts: nil)
        }
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
