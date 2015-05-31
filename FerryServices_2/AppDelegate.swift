//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

struct AppConstants {
    static let parseChannelPrefix = "S"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        // Setup 3rd party frameworks
        Flurry.setCrashReportingEnabled(false)
        Flurry.startSession(APIKeys.FlurryAPIKey)
        
        Crashlytics.startWithAPIKey(APIKeys.CrashlyticsAPIKey)
        
        Parse.setApplicationId(APIKeys.ParseApplicationId, clientKey: APIKeys.ParseClientKey)

        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        
        // Global colors
        self.window?.tintColor = UIColor.tealTintColor()
        
        // Configure push notifications
        let userNotificationTypes = UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound
        let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and save it to Parse.
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackgroundWithBlock { success, error in
            
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if let aps = userInfo["aps"] as? [String: String] {
            let alertViewController = UIAlertController(title: "Alert", message: aps["alert"], preferredStyle: UIAlertControllerStyle.Alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alertViewController.addAction(okAction)
            
            self.window?.rootViewController?.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
}

