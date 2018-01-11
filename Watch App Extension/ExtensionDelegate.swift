//
//  ExtensionDelegate.swift
//  Watch App Extension
//
//  Created by Stefan Church on 7/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import WatchConnectivity

struct Defaults {
    static let subscribedServiceIdsKey = "com.ferryservices.userdefaultkeys.subscribedservices"
}

enum RequestResult<T> {
    case result(result: T)
    case error(error: NSError)
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    //MARK: - Class functions
    fileprivate class func setDefaultServiceToServiceWithId(_ serviceId: Int, forServices services: [Service]) {
        for service in services {
            service.isDefault = service.serviceId == serviceId
        }
    }
    
    //MARK: - Properties
    lazy var defaultServices: [Service] = {
        var services = [Service]()
        
        guard let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json") else {
            return services
        }
        
        do {
            let serviceData = try Data(contentsOf: URL(fileURLWithPath: defaultServicesFilePath), options: .mappedIfSafe)
            if let serviceStatusData = try JSONSerialization.jsonObject(with: serviceData, options: []) as? [[String: AnyObject]] {
                let possibleServices = serviceStatusData.map { Service(json: $0) }
                services = possibleServices.flatMap { $0 } // remove nils
                services = services.sorted { $0.sortOrder < $1.sortOrder }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return services
    }()
    
    fileprivate var subscribedServiceIds: [Int]? {
        get {
            return UserDefaults.standard.array(forKey: Defaults.subscribedServiceIdsKey) as? [Int]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Defaults.subscribedServiceIdsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate var defaultServiceIdToShow: Int? // Set when we receive a notification if we are currently fetching service IDs
    fileprivate var subscribedServicesFetcher = SubscribedServicesFetcher()
    
    //MARK: - Lifecyle
    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()

        configureApp()
    }
    
    //MARK: - Notification handling
    func handleAction(withIdentifier identifier: String?, forRemoteNotification remoteNotification: [AnyHashable: Any]) {
        guard let serviceId = remoteNotification["service_id"] as? Int else {
            return
        }
        
        guard self.subscribedServicesFetcher.state == .stopped else {
            self.defaultServiceIdToShow = serviceId
            return
        }
        
        reloadServicesWithDefaultServiceId(serviceId)
    }
    
    //MARK: - App configuration
    internal func configureApp() {
        if self.subscribedServiceIds == nil {
            WKInterfaceController.reloadRootControllers(withNames: ["Loading"], contexts: nil)
            
            let semaphore = DispatchSemaphore(value: 0)
            
            ProcessInfo().performExpiringActivity(withReason: "Sync subscribed services") { expired in
                guard !expired else {
                    semaphore.signal()
                    return
                }
                
                let timeout = DispatchTime.now() + Double(Int64(10 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                let _ = semaphore.wait(timeout: timeout)
            }
            
            subscribedServicesFetcher.fetchSubscribedServicesIdsWithCompletion { result in
                defer {
                    semaphore.signal()
                }
                
                switch result {
                case let .result(subscribedServiceIds):
                    self.subscribedServiceIds = subscribedServiceIds
                    self.reloadServicesWithDefaultServiceId(self.defaultServiceIdToShow)
                    self.defaultServiceIdToShow = nil
                case let .error(error):
                    WKInterfaceController.reloadRootControllers(withNames: ["ErrorState"], contexts: [error.localizedDescription])
                }
            }
        }
        else {
            reloadServicesWithDefaultServiceId(nil)
        }
    }
    
    //MARK: - Utility methods
    fileprivate func reloadServicesWithDefaultServiceId(_ defaultServiceId: Int?) {
        var services: [Service]
        
        if let defaultServiceId = defaultServiceId {
            ensureServiceIdInSubscribedServiceIds(defaultServiceId)
            services = generateSubscribedServices()
            ExtensionDelegate.setDefaultServiceToServiceWithId(defaultServiceId, forServices: services)
        }
        else {
            services = generateSubscribedServices()
        }
        
        if services.count > 0 {
            WKInterfaceController.reloadRootControllers(withNames: Array(repeating: "ServiceDetail", count: services.count), contexts: services)
        }
        else {
            WKInterfaceController.reloadRootControllers(withNames: ["EmptyState"], contexts: nil)
        }
    }
    
    fileprivate func ensureServiceIdInSubscribedServiceIds(_ serviceId: Int) {
        var subscribedServiceIds = self.subscribedServiceIds ?? [Int]()
        if !subscribedServiceIds.contains(serviceId) {
            subscribedServiceIds.append(serviceId)
        }
        self.subscribedServiceIds = subscribedServiceIds
    }
    
    fileprivate func generateSubscribedServices() -> [Service] {
        guard let currentServiceIds = self.subscribedServiceIds else {
            return [Service]()
        }
        
        let services: [Service] = currentServiceIds.map { serviceId in
            if let index = defaultServices.index( where: { $0.serviceId == serviceId } ) {
                return defaultServices[index]
            }
            else  {
                return Service(serviceId: serviceId, sortOrder: 0, area: "", route: "", status: .unknown)
            }
        }
        
        return services.sorted { $0.sortOrder < $1.sortOrder }
    }
    
}

extension ExtensionDelegate: WCSessionDelegate {
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard subscribedServicesFetcher.state == .stopped else {
            return
        }
        
        guard let receivedServiceIds = applicationContext["subscribedServiceIds"] as? [Int] else {
            return
        }
        
        let sortedReceivedServiceIds = receivedServiceIds.sorted()
        
        let localServiceIds = self.subscribedServiceIds ?? [Int]()
        let sortedLocalServiceIds = localServiceIds.sorted()
        
        if sortedReceivedServiceIds != sortedLocalServiceIds {
            self.subscribedServiceIds = receivedServiceIds
            reloadServicesWithDefaultServiceId(nil)
        }
    }
    
}

