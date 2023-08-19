//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    
    @Published var presentedServiceID: Int?
    @Published var showNotificationMessage: Bool = false
    
    private (set) var notificationMessage = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SentrySDK.start { options in
            options.dsn = "https://57b7260ca4a249ecb24c7975ae3ad79d@o434952.ingest.sentry.io/5392740"
        }
        
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])

        // Configure push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if (granted) {
                    UIApplication.shared.registerForRemoteNotifications()
                }                
            }
        }
        
        
        if let remoteNotificationUserInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            handleNotification(userInfo: remoteNotificationUserInfo)
        }
        
        // Remove old shortcut items
        application.shortcutItems?.removeAll()
        
        return true
    }
    
    // MARK: - Push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        APIClient.createInstallation(installationID: Installation.id, deviceToken: token, completion: { result in
            if case .success = result {
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.registeredForNotifications)
            }            
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // App in foreground
        completionHandler([.list, .banner])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // App became active
        handleNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let info = userInfo as? [String: AnyObject] else { return }
        if let serviceID = info["service_id"] as? Int {
            presentedServiceID = serviceID
        } else {
            guard let aps = info["aps"] as? [String: AnyObject] else { return }
            guard let message = aps["alert"] as? String else { return }
            notificationMessage = message
            showNotificationMessage = true
        }
    }
    
}

