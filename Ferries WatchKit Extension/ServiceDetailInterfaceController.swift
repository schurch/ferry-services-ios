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
    
    @IBOutlet weak var labelBody: WKInterfaceLabel!
    @IBOutlet weak var labelHeader: WKInterfaceLabel!
    @IBOutlet weak var labelStatus: WKInterfaceLabel!
    @IBOutlet weak var imageViewStatus: WKInterfaceImage!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let status = context as? ServiceStatus {
            self.labelHeader.setText(status.route)
            
            if let disruptionStatus = status.disruptionStatus {
                switch disruptionStatus {
                case .Normal:
                    self.labelBody.setText("There are currently no disruptions with this service")
                    self.labelStatus.setText("Normal")
                    self.imageViewStatus.setImageNamed("green")
                case .SailingsAffected:
                    self.labelBody.setText("There are disruptions with this service")
                    self.labelStatus.setText("Disrupted")
                    self.imageViewStatus.setImageNamed("amber")
                case .SailingsCancelled:
                    self.labelBody.setText("Sailings have been cancelled for this service")
                    self.labelStatus.setText("Cancelled")
                    self.imageViewStatus.setImageNamed("red")
                case .Unknown:
                    self.labelBody.setText("There was an error fetching the disruption information for this service")
                    self.labelStatus.setText("Unknown")
                    self.imageViewStatus.setImageNamed(nil)
                }
            }
            
            if let serviceId = status.serviceId {
                self.updateUserActivity(UserActivityTypes.viewService, userInfo: [UserActivityUserInfoKeys.serviceId: serviceId], webpageURL: nil)
            }
        }   
    }
}
