//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry

enum UserDefaultsKeys {
    static let subscribedService = "com.ferryservices.userdefaultkeys.subscribedservices.v2"
    static let registeredForNotifications = "com.ferryservices.userdefaultkeys.registeredForNotifications"
}

struct Installation {
    static let id: UUID = {
        let key = "installationID"
        
        if let id = UserDefaults.standard.string(forKey: key) {
            return UUID(uuidString: id)!
        } else {
            let id = UUID()
            UserDefaults.standard.set(id.uuidString, forKey: key)
            return id
        }
    }()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
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
        
        window?.tintColor = UIColor(named: "Tint")
        
        if let remoteNotificationUserInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            handleNotification(userInfo: remoteNotificationUserInfo)
        }
        
        // Remove old shortcut items
        application.shortcutItems?.removeAll()
        
        let navigationController = window!.rootViewController as! UINavigationController
        navigationController.setViewControllers([ServicesView.createViewController(navigationController: navigationController)], animated: false)
        
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
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // App became active
        handleNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let info = userInfo as? [String: AnyObject] else { return }
        if let serviceID = info["service_id"] as? Int {
            showDetails(forServiceID: serviceID)
        } else {
            guard let aps = info["aps"] as? [String: AnyObject] else { return }
            guard let message = aps["alert"] as? String else { return }
            
            let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Utility methods
    private func showDetails(forServiceID serviceId: Int) {
        guard
            let navigationController = window?.rootViewController as? UINavigationController,
            let servicesViewController = navigationController.viewControllers.first else { return }
        
        let serviceDetailViewController = ServiceDetailsView.createViewController(
            serviceID: serviceId,
            service: Service.defaultServices.first(where: { $0.serviceId == serviceId }),
            navigationController: navigationController
        )
        
        navigationController.setViewControllers([servicesViewController, serviceDetailViewController], animated: true)
    }
    
}

