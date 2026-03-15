//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry

class AppDelegate: UIResponder, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    private var isRequestingNotificationAuthorization = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = AppConfig.sentryDSN
        }
        
        AppPreferences.shared.registerDefaults()
        
        UNUserNotificationCenter.current().delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Remove old shortcut items
        application.shortcutItems?.removeAll()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        handleDidBecomeActive()
    }

    @objc
    private func handleDidBecomeActiveNotification() {
        handleDidBecomeActive()
    }

    private func handleDidBecomeActive() {
        Task { @MainActor in
            await syncPushAuthorizationAndRegistrationIfNeeded()
        }
    }

    @MainActor
    private func syncPushAuthorizationAndRegistrationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            guard !isRequestingNotificationAuthorization else { return }
            isRequestingNotificationAuthorization = true
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } catch {
                print("Failed get permissions for notifications: \(error)")
            }
            isRequestingNotificationAuthorization = false
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            do {
                let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                try await APIClient.createInstallation(installationID: Installation.id, deviceToken: token)
                AppPreferences.shared.isRegisteredForNotifications = true
                NotificationCenter.default.post(name: .registeredForNotifications, object: self)
            } catch {
                print("Error creating installation: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // App in foreground
        [.list, .banner]
    }
    
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let data = NotificationData(response.notification.request.content.userInfo)
        await self.handleNotification(data: data)
    }
    
    @MainActor
    private func handleNotification(data: NotificationData?) async {
        guard let data = data else { return }
        switch data {
        case .service(let serviceID):
            await showDetails(forServiceID: serviceID)
        case .text(let message):
            AppNavigationState.shared.alertMessage = message
        }
    }
    
    // MARK: - Utility methods
    @MainActor
    private func showDetails(forServiceID serviceId: Int) async {
        let serviceFromList: Service?
        do {
            let services = try await APIClient.fetchServices()
            serviceFromList = services.first(where: { $0.serviceId == serviceId })
        } catch {
            serviceFromList = nil
        }
        
        let seedService = serviceFromList ?? Service.defaultServices.first(where: { $0.serviceId == serviceId })
        if seedService == nil {
            let message = "Unknown push service_id: \(serviceId)"
            print(message)
            SentrySDK.capture(message: message)
        }
        
        AppNavigationState.shared.path = []
        AppNavigationState.shared.pushServiceDetails(
            serviceID: serviceId,
            seedService: seedService
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
