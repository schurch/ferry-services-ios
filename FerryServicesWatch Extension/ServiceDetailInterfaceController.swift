//
//  ServiceDetailInterfaceController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 18/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommonWatch

class ServiceDetailInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var imageViewStatus: WKInterfaceImage!
    @IBOutlet weak var labelHeader: WKInterfaceLabel!
    @IBOutlet weak var labelStatus: WKInterfaceLabel!
    @IBOutlet weak var labelUpdated: WKInterfaceLabel!
    
    var serviceId: Int!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.serviceId = context as! Int
    }
    
    override func willActivate() {
        self.updateUserActivity(UserActivityTypes.viewService, userInfo: [UserActivityUserInfoKeys.serviceId: self.serviceId], webpageURL: nil)
    }
    
    // MARK: - Fetch details
    func fetchServiceStatus() {
        self.configureLoadingState()
        ServicesAPIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(self.serviceId) { disruptionsDetails, error in
            self.configureWithDetails(disruptionsDetails!)
        }
    }
    
    // MARK: - View configuration
    func configureWithDetails(status: DisruptionDetails) {
        self.setTitle(status.area)
        
        self.labelHeader.setText(status.route)
        
        self.labelUpdated.setText("Updated just now")
        
        if let disruptionStatus = status.disruptionStatus {
            switch disruptionStatus {
            case .Normal:
                self.labelStatus.setText("Normal")
                self.imageViewStatus.setImageNamed("green")
            case .SailingsAffected:
                self.labelStatus.setText("Disrupted")
                self.imageViewStatus.setImageNamed("amber")
            case .SailingsCancelled:
                self.labelStatus.setText("Cancelled")
                self.imageViewStatus.setImageNamed("red")
            case .Unknown:
                self.labelStatus.setText("Unknown")
                self.imageViewStatus.setImageNamed(nil)
            }
        }
    }
    
    func configureLoadingState() {
        self.labelUpdated.setText("Updating...")
        self.labelHeader.setText("")
        self.labelStatus.setText("")
        self.imageViewStatus.setImageNamed(nil)
    }
}
