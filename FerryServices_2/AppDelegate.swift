//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import FerryServicesCommon

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
        
        // Listen for network requests
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "networkRequestStarted:", name: JSONRequester.requestStartedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "networkRequestFinished:", name: JSONRequester.requestFinishedNotification, object: nil)
        
        // Configure push notifications
        let userNotificationTypes = UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound
        let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func networkRequestStarted(notification: NSNotification) {
        PFNetworkActivityIndicatorManager.sharedManager().incrementActivityCount()
    }
    
    func networkRequestFinished(notification: NSNotification) {
        PFNetworkActivityIndicatorManager.sharedManager().decrementActivityCount()
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
    
    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        let action: String = userInfo!["action"] as! String
        
//        if action == "fetch_service_details" {
//            APIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
//                if error != nil {
//                    reply(["response": "error", "error_details": "There was a problem fetching the service statuses."])
//                }
//                
//                let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.stefanchurch.ferryservices")
//                println(containerURL)
//                reply(["response": containerURL!.absoluteString!])
//            }
//        }
        
//        reply(["response": "no_action_performed"])
    }
}

