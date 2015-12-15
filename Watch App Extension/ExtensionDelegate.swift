//
//  ExtensionDelegate.swift
//  Watch App Extension
//
//  Created by Stefan Church on 7/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import WatchConnectivity

let subscribedServiceIdsUserDefaultsKey = "com.ferryservices.userdefaultkeys.subscribedservices"

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
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
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return services
    }()
    
    func applicationDidFinishLaunching() {
        guard WCSession.isSupported() else {
            print("Sessions not supported")
            return
        }
        
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()
        
        reloadServices()
    }
    
    func applicationDidBecomeActive() {
        
    }
    
    func applicationWillResignActive() {
        
    }
    
    private func reloadServices() {
        guard let currentServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey(subscribedServiceIdsUserDefaultsKey) as? [Int] else {
            WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
            return
        }
        
        if currentServiceIds.count > 0 {
            let services: [Service] = currentServiceIds.map { serviceId in
                if let index = defaultServices.indexOf( { $0.serviceId == serviceId } ) {
                    return defaultServices[index]
                }
                else  {
                    return Service(serviceId: serviceId, sortOrder: 0, area: "", route: "", status: .Unknown)
                }
            }
            
            WKInterfaceController.reloadRootControllersWithNames(Array(count: currentServiceIds.count, repeatedValue: "ServiceDetail"), contexts: services)
        }
        else {
            WKInterfaceController.reloadRootControllersWithNames(["EmptyState"], contexts: nil)
        }
    }
    
}

extension ExtensionDelegate: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        guard let subscribedServiceIds = applicationContext["subscribedServiceIds"] as? [Int] else {
            return
        }
        
        let sortedServices = subscribedServiceIds.sort()
        if let serviceIds = NSUserDefaults.standardUserDefaults().arrayForKey(subscribedServiceIdsUserDefaultsKey) as? [Int] {
            let localSortedServiceIds = serviceIds.sort()
            if sortedServices != localSortedServiceIds {
                NSUserDefaults.standardUserDefaults().setObject(sortedServices, forKey: subscribedServiceIdsUserDefaultsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                
                reloadServices()
            }
        }
    }
    
}

