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

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        
        Flurry.setCrashReportingEnabled(false)
        Flurry.startSession("48Q89W7B39FXGJK9BSW6")
        
//        Crashlytics.startWithAPIKey("9aad7798d2e2d712649ba35bd1747beeac29b07f")

        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        
        self.window?.tintColor = UIColor(red: 230.0/255.0, green: 35.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        
        return true
    }
}

