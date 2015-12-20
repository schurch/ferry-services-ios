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
    
    private var subscribedServicesExist: Bool {
        return self.subscribedServiceIds != nil
    }
    
    private var subscribedServiceIds: [Int]? {
        get {
            return NSUserDefaults.standardUserDefaults().arrayForKey(Defaults.subscribedServiceIdsKey) as? [Int]
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Defaults.subscribedServiceIdsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var fetchingServiceIds: Bool = false
    private var defaultServiceIdToShow: Int?
    
    //MARK: - Lifecyle
    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()
        
        if !subscribedServicesExist {
            fetchSubscribedServiceIdsWithCompletion { result in
                switch result {
                case let .Result(serviceIds):
                    self.subscribedServiceIds = serviceIds
                    
                    if let defaultServiceId = self.defaultServiceIdToShow {
                        self.reloadServicesWithDefaultServiceId(defaultServiceId)
                        self.defaultServiceIdToShow = nil
                    }
                    else {
                        self.reloadServicesWithDefaultServiceId(nil)
                    }
                case .Error:
                    WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
                }
            }
        }
        else {
            reloadServicesWithDefaultServiceId(nil)
        }
    }
    
    //MARK: - Notification handling
    func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
        guard let serviceId = remoteNotification["service_id"] as? Int else {
            return
        }
        
        guard !fetchingServiceIds else {
            self.defaultServiceIdToShow = serviceId
            return
        }
        
        let configureApp = {
            var serviceIds = self.subscribedServiceIds ?? [Int]()
            if !serviceIds.contains(serviceId) {
                serviceIds.append(serviceId)
                self.subscribedServiceIds = serviceIds
            }
            
            self.reloadServicesWithDefaultServiceId(serviceId)
        }
        
        if !subscribedServicesExist {
            fetchSubscribedServiceIdsWithCompletion { result in
                switch result {
                case let .Result(serviceIds):
                    self.subscribedServiceIds = serviceIds
                    configureApp()
                case .Error:
                    configureApp()
                }
            }
        }
        else {
            configureApp()
        }
    }
    
    //MARK: - Utility methods
    private func fetchSubscribedServiceIdsWithCompletion(completion: RequestResult<[Int]> -> Void) {
        guard !fetchingServiceIds else {
            return
        }
        
        fetchingServiceIds = true
        
        WKInterfaceController.reloadRootControllersWithNames(["Loading"], contexts: nil)
        
        WCSession.defaultSession().sendMessage(["action": "fetchSubscribedServices"], replyHandler: { response in
            dispatch_async(dispatch_get_main_queue(), {
                if let subscribedServiceIds = response["subscribedServiceIds"] as? [Int] {
                    completion(.Result(result: subscribedServiceIds))
                }
                else {
                    let empty = [Int]()
                    completion(.Result(result: empty))
                }
                
                self.fetchingServiceIds = false
            })
        }, errorHandler: { error in
            dispatch_async(dispatch_get_main_queue(), {
                completion(.Error(error: error))
                self.fetchingServiceIds = false
            })
        })
    }
    
    private func reloadServicesWithDefaultServiceId(defaultServiceId: Int?) {
        let services = generateSubscribedServices()
        
        if let defaultServiceId = defaultServiceId {
            setDefaultServiceToServiceWithId(defaultServiceId, forServices: services)
        }
        
        if services.count > 0 {
            WKInterfaceController.reloadRootControllersWithNames(Array(count: services.count, repeatedValue: "ServiceDetail"), contexts: services)
        }
        else {
            WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
        }
    }
    
    private func setDefaultServiceToServiceWithId(serviceId: Int, forServices services: [Service]) {
        if let defaultService = services.filter( {$0.serviceId == serviceId} ).first {
            defaultService.isDefault = true
        }
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
        guard !fetchingServiceIds else {
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

