//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import FerryServicesCommon

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        Flurry.setCrashReportingEnabled(false)
        Flurry.startSession(APIKeys.FlurryAPIKey)
        
        Crashlytics.startWithAPIKey(APIKeys.CrashlyticsAPIKey)

        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        
        self.window?.tintColor = UIColor.tealTintColor()
        
        return true
    }
    
    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        let action: String = userInfo!["action"] as! String
        
//        if action == "fetch_service_details" {
            APIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
                if error != nil {
                    reply(["response": "error", "error_details": "There was a problem fetching the service statuses."])
                }
                
                let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.stefanchurch.ferryservices")
//                println(containerURL)
                reply(["response": containerURL!.absoluteString!])
            }
//        }
        
//        reply(["response": "no_action_performed"])
    }
}

