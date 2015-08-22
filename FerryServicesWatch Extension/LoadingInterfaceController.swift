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

class LoadingInterfaceController: WKInterfaceController {
    
    @IBOutlet var labelLoading: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
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
    
}
