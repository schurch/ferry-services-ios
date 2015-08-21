//
//  LoadingInterfaceController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/08/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommonWatch
import CoreLocation

class LoadingInterfaceController: WKInterfaceController {
    
    @IBOutlet var labelLoading: WKInterfaceLabel!
    
    let locationManager = CLLocationManager()
    
    var isRequestingLocation = false
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.locationManager.delegate = self
        
        if let recentServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey("recentServiceIds") as? [Int] {
            if recentServiceIds.count > 0 {
                ServicesAPIClient.sharedInstance.fetchFerryServicesWithCompletion { services, error in
                    guard let services = services else {
                        return
                    }
                    
                    let recentServices = services.filter { service in
                        if let serviceId = service.serviceId {
                            return recentServiceIds.contains(serviceId)
                        }
                        
                        return false
                    }
                    
                    let controllers = Array(count: recentServiceIds.count, repeatedValue: "serviceDetail")
                    WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: recentServices)
                }
            }
            else {
                self.requestLocation()
            }
        }
        else {
            self.requestLocation()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func requestLocation() {
        guard !self.isRequestingLocation else {
            return
        }
        
        self.labelLoading.setText("Searching for\nnearest port...")
        
        self.isRequestingLocation = true
        
        self.locationManager.requestLocation()
    }
    
}

extension LoadingInterfaceController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            let lastLocationCoordinate = locations.last!.coordinate
            print("Location: \(lastLocationCoordinate)")
            
            self.isRequestingLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Error fetching location: \(error)")
            
            self.isRequestingLocation = false
        }
    }
}
