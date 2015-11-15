//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

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
        
        // Global colors
        self.window?.tintColor = UIColor.tealTintColor()
        
        // Configure push notifications
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
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
        PFPush.handlePush(userInfo)
    }
}

