//
//  InterfaceController.swift
//  Ferries WatchKit Extension
//
//  Created by Stefan Church on 23/05/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommonWatch

class ServiceListInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var labelLastUpdated: WKInterfaceLabel!
    @IBOutlet weak var table: WKInterfaceTable!
    
    var lastUpdated: NSDate!
    
    var services: [ServiceStatus]?
    
    // MARK: - Lifecycle
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
//        configureLastUpdated()
//        configureTable()
    }
    
    override func willActivate() {
        super.willActivate()
        
//        configureLastUpdated()
//        configureTable()
    }
    
    // MARK: -
    func refreshWithCompletion(completion: () -> ()) {
        self.services = nil
        
        ServicesAPIClient.sharedInstance.fetchFerryServicesWithCompletion { services, error in
            if error != nil || services == nil {
                return
            }
            
            self.services = services
            self.lastUpdated = NSDate()
            
            completion()
        }
    }
    
    func configureLastUpdated() {
        if let updatedDate = self.lastUpdated {
            
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let components = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: updatedDate, toDate: NSDate(), options: [])
            
            var updated: String
            
            if components.day > 0 {
                updated = "\(components.day)d ago"
            }
            else if components.hour > 0 {
                updated = "\(components.hour)h ago"
            }
            else {
                if components.minute == 0 {
                    updated = "just now"
                }
                else {
                    updated = "\(components.minute)m ago"
                }
            }
            
            self.labelLastUpdated.setText("Updated \(updated)")
        }
    }
    
    // MARK: -
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if let services = self.services {
            return services[rowIndex]
        }
        
        return nil
    }
    
    // MARK: - Table config
    func configureTable() {
        if let services = self.services {
            self.table.setNumberOfRows(services.count, withRowType: "serviceRow")
            
            for var index = 0; index < services.count; index++ {
                let serviceStatus = services[index]
                
                let row = self.table.rowControllerAtIndex(index) as! ServiceRow
                
                if let route = serviceStatus.route {
                    row.serviceLabel.setText(route)
                }
                
                if let disruptionStatus = serviceStatus.disruptionStatus {
                    switch disruptionStatus {
                    case .Normal:
                        row.serviceStatusImage.setImageNamed("green")
                    case .SailingsAffected:
                        row.serviceStatusImage.setImageNamed("amber")
                    case .SailingsCancelled:
                        row.serviceStatusImage.setImageNamed("red")
                    case .Unknown:
                        row.serviceStatusImage.setImage(nil)
                    }
                }
            }
        }
        else {
            self.table.setNumberOfRows(0, withRowType: "serviceRow")
        }
    }
    
}
