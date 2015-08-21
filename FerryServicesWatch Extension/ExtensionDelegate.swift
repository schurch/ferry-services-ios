//
//  ExtensionDelegate.swift
//  FerryServicesWatch Extension
//
//  Created by Stefan Church on 24/07/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }

    func applicationDidBecomeActive() {
        
    }

    func applicationWillResignActive() {
        
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
