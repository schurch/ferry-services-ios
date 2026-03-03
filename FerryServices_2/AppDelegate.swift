//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://57b7260ca4a249ecb24c7975ae3ad79d@o434952.ingest.sentry.io/5392740"
        }
        
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])
        
        UNUserNotificationCenter.current().delegate = self
        
        // Remove old shortcut items
        application.shortcutItems?.removeAll()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } catch {
                print("Failed get permissions for notifications: \(error)")
            }
        }
    }
    
    // MARK: - Push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            do {
                let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                try await APIClient.createInstallation(installationID: Installation.id, deviceToken: token)
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.registeredForNotifications)
                NotificationCenter.default.post(name: .registeredForNotifications, object: self)
            } catch {
                print("Error creating installation: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // App in foreground
        [.list, .banner]
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // App became active
        let data = NotificationData(response.notification.request.content.userInfo)
        handleNotification(data: data)
    }
    
    private nonisolated func handleNotification(data: NotificationData?) {
        guard let data = data else { return }
        switch data {
        case .service(let serviceID):
            showDetails(forServiceID: serviceID)
        case .text(let message):
            Task { @MainActor in
                AppNavigationState.shared.alertMessage = message
            }
        }
    }
    
    // MARK: - Utility methods
    private nonisolated func showDetails(forServiceID serviceId: Int) {
        Task { @MainActor in
            AppNavigationState.shared.path = [.serviceDetails(serviceId)]
        }
    }
    
}
