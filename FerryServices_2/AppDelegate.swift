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
        
        Parse.setApplicationId(APIKeys.ParseApplicationId, clientKey: APIKeys.ParseClientKey)
        print("Parse App ID: \(APIKeys.ParseApplicationId); Parse Client key: \(APIKeys.ParseClientKey)")
        
        // Global colors
        self.window?.tintColor = UIColor.tealTintColor()
        
        // Configure push notifications
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let notificationSettings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        
        guard let shortcut = launchedShortcutItem else {
            return
        }
        
        handleShortCutItem(shortcut)
        launchedShortcutItem = nil
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

    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: Bool -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        completionHandler(handledShortCutItem)
    }

    
    // MARK: -
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            if let servicesViewController = navigationController.viewControllers.first as? ServicesViewController {
                if let serviceId = shortcutItem.userInfo?[AppDelegate.applicationShortcutUserInfoKeyServiceId] as? Int {
                    servicesViewController.showDetailsForServiceId(serviceId)
                    handled = true
                }
            }
        }
        
        return handled
    }
}

