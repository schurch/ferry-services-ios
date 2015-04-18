//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

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
}

