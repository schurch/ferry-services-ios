//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import FerryServicesCommonTouch
import WatchConnectivity

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
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
            
            self.sendWatchAppContext()
        }
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        self.sendWatchAppContext()
    }
    
    // MARK: - Watch context updates
    func sendWatchAppContext() {
        guard WCSession.isSupported() else {
            print("Watch sessions not supported")
            return
        }
        
        let session = WCSession.defaultSession()
        
        if session.paired && session.watchAppInstalled {
            if let serviceIds = self.recentServiceIds() {
                do {
                    try session.updateApplicationContext(["recentServiceIds": serviceIds])
                }
                catch let error as NSError {
                    print("Error sending context to watch: \(error)")
                }
            }
        }
    }
    
    func recentServiceIds() -> [Int]? {
        if let tapCounts = NSUserDefaults.standardUserDefaults().dictionaryForKey(ServicesViewController.Constants.TapCount.userDefaultsKey) as? [String: Int] {
            let recents = tapCounts.filter { (serviceId, tapCount) in
                tapCount >= ServicesViewController.Constants.TapCount.minimumCount
            }
            
            let recentServiceIds = recents.map { (serviceId, tapCount) in
                return Int(serviceId)!
            }
            
            return recentServiceIds
        }
        
        return nil
    }
    
    // MARK: - Network acitvity indicator handling
    func networkRequestStarted(notification: NSNotification) {
        PFNetworkActivityIndicatorManager.sharedManager().incrementActivityCount()
    }
    
    func networkRequestFinished(notification: NSNotification) {
        PFNetworkActivityIndicatorManager.sharedManager().decrementActivityCount()
    }
    
    // MARK: - Notification handling
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
    
    // MARK: - Handoff
    func application(application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        if userActivityType == UserActivityTypes.viewService {
            return true
        }
        
        return false
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        if userActivity.activityType == UserActivityTypes.viewService {
            if let navigationController = self.window?.rootViewController as? UINavigationController {
                if let servicesViewController = navigationController.viewControllers.first as? ServicesViewController {
                    restorationHandler([servicesViewController])
                    return true
                }
            }
        }
        
        return false
    }
}

extension AppDelegate: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let action = message["action"] as? String {
            switch action {
            case "sendRecentServiceIds":
                if let servicesIds = self.recentServiceIds() {
                    replyHandler(["recentServiceIds": servicesIds])
                }
            default:
                print("Unrecognized action sent from watch")
            }
        }
    }
    
}
