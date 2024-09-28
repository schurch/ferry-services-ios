//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://57b7260ca4a249ecb24c7975ae3ad79d@o434952.ingest.sentry.io/5392740"
        }
        
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])
        
        UNUserNotificationCenter.current().delegate = self
        
        window?.tintColor = .colorTint
        
        if let remoteNotificationUserInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            let data = NotificationData(remoteNotificationUserInfo)
            handleNotification(data: data)
        }
        
        // Remove old shortcut items
        application.shortcutItems?.removeAll()
        
        let navigationController = window!.rootViewController as! UINavigationController
        navigationController.setViewControllers([ServicesView.createViewController(navigationController: navigationController)], animated: false)
        
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
        await handleNotification(data: data)
    }
    
    private func handleNotification(data: NotificationData?) {
        guard let data = data else { return }
        switch data {
        case .service(let serviceID):
            showDetails(forServiceID: serviceID)
        case .text(let message):
            let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Utility methods
    private func showDetails(forServiceID serviceId: Int) {
        guard
            let navigationController = window?.rootViewController as? UINavigationController,
            let servicesViewController = navigationController.viewControllers.first 
        else {
            return
        }
        
        let serviceDetailViewController = ServiceDetailsView.createViewController(
            serviceID: serviceId,
            service: Service.defaultServices.first(where: { $0.serviceId == serviceId }),
            navigationController: navigationController
        )
        
        navigationController.setViewControllers([servicesViewController, serviceDetailViewController], animated: true)
    }
    
}

private enum NotificationData: Sendable {
    case service(serviceID: Int)
    case text(message: String)
    
    init?(_ data: [AnyHashable : Any]) {
        guard let info = data as? [String: AnyObject] else {
            return nil
        }
        if let serviceID = info["service_id"] as? Int {
            self = .service(serviceID: serviceID)
        } else {
            guard
                let aps = info["aps"] as? [String: AnyObject],
                let message = aps["alert"] as? String
            else {
                return nil
            }
            
            self = .text(message: message)
        }
    }
}
