//
//  AppDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Sentry
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    private let navigationState = AppNavigationState()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://57b7260ca4a249ecb24c7975ae3ad79d@o434952.ingest.sentry.io/5392740"
        }
        
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])
        
        UNUserNotificationCenter.current().delegate = self
        
        window?.tintColor = .colorTint
        let rootView = RootView(navigationState: navigationState)
        window?.rootViewController = UIHostingController(rootView: rootView)
        window?.makeKeyAndVisible()
        
        if let remoteNotificationUserInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            let data = NotificationData(remoteNotificationUserInfo)
            handleNotification(data: data)
        }
        
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
        await handleNotification(data: data)
    }
    
    private func handleNotification(data: NotificationData?) {
        guard let data = data else { return }
        switch data {
        case .service(let serviceID):
            showDetails(forServiceID: serviceID)
        case .text(let message):
            Task { @MainActor in
                navigationState.alertMessage = message
            }
        }
    }
    
    // MARK: - Utility methods
    private func showDetails(forServiceID serviceId: Int) {
        Task { @MainActor in
            navigationState.path = [.serviceDetails(serviceId)]
        }
    }
    
}

@MainActor
private final class AppNavigationState: ObservableObject {
    enum Destination: Hashable {
        case serviceDetails(Int)
        case map(UUID)
        case webInfo(UUID)
    }

    @Published var path: [Destination] = [] {
        didSet {
            pruneNavigationPayloads()
        }
    }
    @Published var alertMessage: String?

    private var mapServices: [UUID: Service] = [:]
    private var webInfoHTML: [UUID: String] = [:]

    func pushMap(service: Service) {
        let id = UUID()
        mapServices[id] = service
        path.append(.map(id))
    }

    func pushWebInfo(html: String) {
        let id = UUID()
        webInfoHTML[id] = html
        path.append(.webInfo(id))
    }

    func mapService(for id: UUID) -> Service? {
        mapServices[id]
    }

    func webInfo(for id: UUID) -> String? {
        webInfoHTML[id]
    }

    private func pruneNavigationPayloads() {
        let mapIDs = Set(
            path.compactMap { destination in
                if case .map(let id) = destination { return id }
                return nil
            }
        )
        mapServices = mapServices.filter { mapIDs.contains($0.key) }

        let webInfoIDs = Set(
            path.compactMap { destination in
                if case .webInfo(let id) = destination { return id }
                return nil
            }
        )
        webInfoHTML = webInfoHTML.filter { webInfoIDs.contains($0.key) }
    }
}

private struct RootView: View {
    @ObservedObject var navigationState: AppNavigationState
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $navigationState.path) {
            ServicesView { service in
                navigationState.path.append(.serviceDetails(service.serviceId))
            }
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheetView()
            }
            .navigationDestination(for: AppNavigationState.Destination.self) { destination in
                switch destination {
                case .serviceDetails(let serviceID):
                    ServiceDetailsView(
                        serviceID: serviceID,
                        service: Service.defaultServices.first(where: { $0.serviceId == serviceID }),
                        showDisruptionInfo: { html in
                            navigationState.pushWebInfo(html: html)
                        },
                        showMap: { service in
                            navigationState.pushMap(service: service)
                        }
                    )
                case .map(let id):
                    if let service = navigationState.mapService(for: id) {
                        MapView(service: service)
                    }
                case .webInfo(let id):
                    if let html = navigationState.webInfo(for: id) {
                        WebInformationView(html: html)
                    }
                }
            }
            .alert("Alert", isPresented: alertIsPresentedBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(navigationState.alertMessage ?? "")
            }
        }
    }

    private var alertIsPresentedBinding: Binding<Bool> {
        Binding(
            get: { navigationState.alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    navigationState.alertMessage = nil
                }
            }
        )
    }
}

private struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsView()
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
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
