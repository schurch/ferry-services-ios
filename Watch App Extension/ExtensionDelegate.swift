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
    case Result(result: T)
    case Error(error: NSError)
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    //MARK: - Class functions
    private class func setDefaultServiceToServiceWithId(serviceId: Int, forServices services: [Service]) {
        for service in services {
            service.isDefault = service.serviceId == serviceId
        }
    }
    
    //MARK: - Properties
    lazy var defaultServices: [Service] = {
        var services = [Service]()
        
        guard let defaultServicesFilePath = NSBundle.mainBundle().pathForResource("services", ofType: "json") else {
            return services
        }
        
        do {
            let serviceData = try NSData(contentsOfFile: defaultServicesFilePath, options: .DataReadingMappedIfSafe)
            if let serviceStatusData = try NSJSONSerialization.JSONObjectWithData(serviceData, options: []) as? [[String: AnyObject]] {
                let possibleServices = serviceStatusData.map { Service(json: $0) }
                services = possibleServices.flatMap { $0 } // remove nils
                services = services.sort { $0.sortOrder < $1.sortOrder }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return services
    }()
    
    private var subscribedServiceIds: [Int]? {
        get {
            return NSUserDefaults.standardUserDefaults().arrayForKey(Defaults.subscribedServiceIdsKey) as? [Int]
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Defaults.subscribedServiceIdsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var defaultServiceIdToShow: Int? // Set when we receive a notification if we are currently fetching service IDs
    private var subscribedServicesFetcher = SubscribedServicesFetcher()
    
    //MARK: - Lifecyle
    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()

        configureApp()
    }
    
    //MARK: - Notification handling
    func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
        guard let serviceId = remoteNotification["service_id"] as? Int else {
            return
        }
        
        guard self.subscribedServicesFetcher.state == .Stopped else {
            self.defaultServiceIdToShow = serviceId
            return
        }
        
        reloadServicesWithDefaultServiceId(serviceId)
    }
    
    //MARK: - Utility methods
    internal func configureApp() {
        if self.subscribedServiceIds == nil {
            WKInterfaceController.reloadRootControllersWithNames(["Loading"], contexts: nil)
            
            let semaphore = dispatch_semaphore_create(0)
            
            NSProcessInfo().performExpiringActivityWithReason("Sync subscribed services") { expired in
                guard !expired else {
                    dispatch_semaphore_signal(semaphore)
                    return
                }
                
                let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * Double(NSEC_PER_SEC)))
                dispatch_semaphore_wait(semaphore, timeout)
            }
            
            subscribedServicesFetcher.fetchSubscribedServicesIdsWithCompletion { result in
                defer {
                    dispatch_semaphore_signal(semaphore)
                }
                
                switch result {
                case let .Result(subscribedServiceIds):
                    self.subscribedServiceIds = subscribedServiceIds
                    self.reloadServicesWithDefaultServiceId(self.defaultServiceIdToShow)
                    self.defaultServiceIdToShow = nil
                case let .Error(error):
                    WKInterfaceController.reloadRootControllersWithNames(["ErrorState"], contexts: [error.localizedDescription])
                }
            }
        }
        else {
            reloadServicesWithDefaultServiceId(nil)
        }
    }
    
    private func reloadServicesWithDefaultServiceId(defaultServiceId: Int?) {
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
            WKInterfaceController.reloadRootControllersWithNames(Array(count: services.count, repeatedValue: "ServiceDetail"), contexts: services)
        }
        else {
            WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
        }
    }
    
    private func ensureServiceIdInSubscribedServiceIds(serviceId: Int) {
        var subscribedServiceIds = self.subscribedServiceIds ?? [Int]()
        if !subscribedServiceIds.contains(serviceId) {
            subscribedServiceIds.append(serviceId)
        }
        self.subscribedServiceIds = subscribedServiceIds
    }
    
    private func generateSubscribedServices() -> [Service] {
        guard let currentServiceIds = self.subscribedServiceIds else {
            return [Service]()
        }
        
        let services: [Service] = currentServiceIds.map { serviceId in
            if let index = defaultServices.indexOf( { $0.serviceId == serviceId } ) {
                return defaultServices[index]
            }
            else  {
                return Service(serviceId: serviceId, sortOrder: 0, area: "", route: "", status: .Unknown)
            }
        }
        
        return services.sort { $0.sortOrder < $1.sortOrder }
    }
    
}

extension ExtensionDelegate: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        guard subscribedServicesFetcher.state == .Stopped else {
            return
        }
        
        guard let receivedServiceIds = applicationContext["subscribedServiceIds"] as? [Int] else {
            return
        }
        
        let sortedReceivedServiceIds = receivedServiceIds.sort()
        
        let localServiceIds = self.subscribedServiceIds ?? [Int]()
        let sortedLocalServiceIds = localServiceIds.sort()
        
        if sortedReceivedServiceIds != sortedLocalServiceIds {
            self.subscribedServiceIds = receivedServiceIds
            reloadServicesWithDefaultServiceId(nil)
        }
    }
    
}

