//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import WatchConnectivity
import Parse

struct AppConstants {
    static let parseChannelPrefix = "S"
}

struct ErrorMessages {
    static let errorFetchingSubscribedServiceIds = "There was an error fetching your subscribed services"
}

let sharedDefaults = UserDefaults(suiteName: "group.stefanchurch.ferryservices")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let applicationShortcutTypeRecentService = "UIApplicationShortcutIconTypeRecentService"
    static let applicationShortcutUserInfoKeyServiceId = "ServiceId"
                            
    var window: UIWindow?
    
    var launchedShortcutItem: UIApplicationShortcutItem? // Saved shortcut item used as a result of an app launch, used later when app is activated.

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        var shouldPerformAdditionalDelegateHandling = true
        
        Crashlytics.start(withAPIKey: APIKeys.CrashlyticsAPIKey)
        
        Parse.initialize(with: ParseClientConfiguration { configuration in
            configuration.applicationId = APIKeys.ParseApplicationId
            #if DEBUG
                configuration.server = "http://test.scottishferryapp.com/parse"
            #else
                configuration.server = "http://www.scottishferryapp.com/parse"
            #endif
        })
        
        // Global colors
        self.window?.tintColor = UIColor.tealTintColor()
        
        // Configure push notifications
        let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.alert, UIUserNotificationType.sound]
        let notificationSettings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            self.launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        else if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            self.application(application, didReceiveRemoteNotification: remoteNotification)
        }
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self;
            session.activate()
        }
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        
        if let shortcut = self.launchedShortcutItem {
            let _ = self.handleShortCutItem(shortcut)
            self.launchedShortcutItem = nil
        }
        
        
        self.sendWatchAppContext()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "scottishferryapp" else {
            return false
        }
        guard let pathComponents = NSURLComponents(string: url.absoluteString)?.path?.components(separatedBy: "/") else {
            return false
        }
        
        guard pathComponents.count > 1 else {
            return false
        }
        
        let lastElements = Array(pathComponents.suffix(2))
        guard lastElements[0] == "services" else {
            return false
        }
        
        guard let serviceId = Int(lastElements[1]) else {
            return false
        }
        
        showDetailsForServiceId(serviceId)
        
        return true
    }
    
    // MARK: - Push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Store the deviceToken in the current installation and save it to Parse.
        let installation = PFInstallation.current()
        installation?.deviceToken = "" // For some reason the installation isn't saving unless we do this before setting the token below.
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground { (success, error) in
            if let error = error {
                print("Error registering device token \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        guard let info = userInfo as? [String: AnyObject] else { return }
        
        if application.applicationState == .active {
            guard let aps = info["aps"] as? [String: AnyObject] else { return }
            guard let message = aps["alert"] as? String else { return }

            let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
                
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
        else {
            if let serviceId = info["service_id"] as? Int {
                self.showDetailsForServiceId(serviceId)
            }
        }
    }
    
    // MARK: - Shortcut items
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        completionHandler(handledShortCutItem)
    }
    
    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        if let serviceId = shortcutItem.userInfo?[AppDelegate.applicationShortcutUserInfoKeyServiceId] as? Int {
            self.showDetailsForServiceId(serviceId)
            handled = true
        }
        
        return handled
    }
    
    // MARK: - Handoff
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
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
        
        let session = WCSession.default()
        
        if session.isPaired && session.isWatchAppInstalled {
            do {
                let serviceIds = UserDefaults.standard.array(forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
                try session.updateApplicationContext(["subscribedServiceIds": serviceIds])
            }
            catch let error as NSError {
                print("Error sending context to watch: \(error)")
            }
        }
    }
    
    // MARK: - Utility methods
    fileprivate func showDetailsForServiceId(_ serviceId: Int) {
        if let navigationController = self.window?.rootViewController as? UINavigationController, let servicesViewController = navigationController.viewControllers.first as? ServicesViewController {
            servicesViewController.showDetailsForServiceId(serviceId, shouldFindAndHighlightRow: true)
        }
    }
    
}

extension AppDelegate: WCSessionDelegate {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        var identifier = UIBackgroundTaskInvalid
        
        identifier = UIApplication.shared.beginBackgroundTask (expirationHandler: {
            replyHandler(["error": ErrorMessages.errorFetchingSubscribedServiceIds])
            
            if identifier != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        })
        
        if let action = message["action"] as? String {
            switch action {
            case "fetchSubscribedServices":
                let serviceIds = UserDefaults.standard.array(forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
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
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }
}

