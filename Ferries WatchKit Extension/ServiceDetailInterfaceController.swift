//
//  ServiceDetailInterfaceController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 18/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommon

class ServiceDetailInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var labelHeader: WKInterfaceLabel!
    @IBOutlet weak var labelBody: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let status = context as? ServiceStatus {
            labelHeader.setText(status.route)
            
            if let disruptionStatus = status.disruptionStatus {
                switch disruptionStatus {
                case .Normal:
                    labelBody.setText("There are currently no disruptions with this service")
                case .SailingsAffected:
                    labelBody.setText("There are disruptions with this service")
                case .SailingsCancelled:
                    labelBody.setText("Sailings have been cancelled for this service")
                case .Unknown:
                    labelBody.setText("There was an error fetching the disruption information for this service")
                }
            }
            
            if let serviceId = status.serviceId {
                self.updateUserActivity("com.stefanchurch.ferryservices.viewservice", userInfo: ["serviceId": serviceId], webpageURL: nil)
            }
        }   
    }
}
