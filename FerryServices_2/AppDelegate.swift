//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import WatchConnectivity
import Flurry_iOS_SDK
import Parse

struct AppConstants {
    static let parseChannelPrefix = "S"
}

struct ErrorMessages {
    static let errorFetchingSubscribedServiceIds = "There was an error fetching your subscribed services"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let applicationShortcutTypeRecentService = "UIApplicationShortcutIconTypeRecentService"
    static let applicationShortcutUserInfoKeyServiceId = "ServiceId"
                            
    var window: UIWindow?
    
    var launchedShortcutItem: UIApplicationShortcutItem? // Saved shortcut item used as a result of an app launch, used later when app is activated.

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        var shouldPerformAdditionalDelegateHandling = true
        
        // Setup 3rd party frameworks
        Flurry.setCrashReportingEnabled(false)
        Flurry.startSession(APIKeys.FlurryAPIKey)
        
        Crashlytics.startWithAPIKey(APIKeys.CrashlyticsAPIKey)
        
        Parse.initializeWithConfiguration(ParseClientConfiguration { configuration in
            configuration.applicationId = APIKeys.ParseApplicationId
            #if DEBUG
                configuration.server = "http://test.scottishferryapp.com/parse"
            #else
                configuration.server = "http://scottishferryapp.com/parse"
            #endif
        })
        
        // Global colors
        self.window?.tintColor = UIColor.tealTintColor()
        
        // Configure push notifications
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            self.launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        else if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            self.application(application, didReceiveRemoteNotification: remoteNotification)
        }
        
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
        }
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        
        if let shortcut = self.launchedShortcutItem {
            self.handleShortCutItem(shortcut)
            self.launchedShortcutItem = nil
        }
        
        
        self.sendWatchAppContext()
    }
    
    // MARK: - Push notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and save it to Parse.
        let installation = PFInstallation.currentInstallation()
        installation.deviceToken = "" // For some reason the installation isn't saving unless we do this before setting the token below.
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if application.applicationState == .Active {
            if let message = userInfo["aps"]?["alert"] as? String {
                let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alertController.addAction(cancelAction)
                
                self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
        }
        else {
            if let serviceId = userInfo["service_id"] as? Int {
                self.showDetailsForServiceId(serviceId)
            }
        }
    }
    
    // MARK: - Shortcut items
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        completionHandler(handledShortCutItem)
    }
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        if let serviceId = shortcutItem.userInfo?[AppDelegate.applicationShortcutUserInfoKeyServiceId] as? Int {
            self.showDetailsForServiceId(serviceId)
            handled = true
        }
        
        return handled
    }
    
    // MARK: - Handoff
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        if userActivity.activityType == "com.stefanchurch.ferryservices.viewservice" {
            if let serviceId = userActivity.userInfo?["serviceId"] as? Int {
                self.showDetailsForServiceId(serviceId)
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Watch context updates
    func sendWatchAppContext() {
        guard WCSession.isSupported() else {
            print("Watch sessions not supported")
            return
        }
        
        let session = WCSession.defaultSession()
        
        if session.paired && session.watchAppInstalled {
            do {
                let serviceIds = NSUserDefaults.standardUserDefaults().arrayForKey(ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
                try session.updateApplicationContext(["subscribedServiceIds": serviceIds])
            }
            catch let error as NSError {
                print("Error sending context to watch: \(error)")
            }
        }
    }
    
    // MARK: - Utility methods
    private func showDetailsForServiceId(serviceId: Int) {
        if let navigationController = self.window?.rootViewController as? UINavigationController, let servicesViewController = navigationController.viewControllers.first as? ServicesViewController {
            servicesViewController.showDetailsForServiceId(serviceId, shouldFindAndHighlightRow: true)
        }
    }
    
}

extension AppDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        var identifier = UIBackgroundTaskInvalid
        
        identifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            replyHandler(["error": ErrorMessages.errorFetchingSubscribedServiceIds])
            
            if identifier != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(identifier)
            }
        }
        
        if let action = message["action"] as? String {
            switch action {
            case "fetchSubscribedServices":
                let serviceIds = NSUserDefaults.standardUserDefaults().arrayForKey(ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
                replyHandler(["subscribedServiceIds": serviceIds])
            default:
                replyHandler(["error": ErrorMessages.errorFetchingSubscribedServiceIds])
                print("Unrecognized action from watch")
            }
        }
        else {
            replyHandler(["error": ErrorMessages.errorFetchingSubscribedServiceIds])
        }
        
        if identifier != UIBackgroundTaskInvalid {
            UIApplication.sharedApplication().endBackgroundTask(identifier)
        }
    }
}

