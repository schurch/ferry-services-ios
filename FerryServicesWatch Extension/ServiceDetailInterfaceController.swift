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
    @IBOutlet weak var labelViewOnPhone: WKInterfaceLabel!
    @IBOutlet weak var separatorOne: WKInterfaceSeparator!
    @IBOutlet weak var separatorTwo: WKInterfaceSeparator!
    
    var serviceId: Int?
    var disruptionDetails: DisruptionDetails?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.serviceId = context as? Int
    }
    
    override func willActivate() {
        self.fetchDisruptionDetails()
        
        if let serviceId = self.serviceId {
            self.updateUserActivity(UserActivityTypes.viewService, userInfo: [UserActivityUserInfoKeys.serviceId: serviceId], webpageURL: nil)
        }
    }
    
    // MARK: - Fetch details
    func fetchDisruptionDetails() {
        if let serviceId = self.serviceId {
            self.configureLoadingState()
            
            ServicesAPIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, error in
                self.disruptionDetails = disruptionDetails
                self.configureView()
            }
        }
    }
    
    // MARK: - View configuration
    func configureView() {
        guard let disruptionDetails = self.disruptionDetails else {
            return
        }
        
        self.setTitle(disruptionDetails.area)
        
        self.labelHeader.setText(disruptionDetails.route)
        
        self.labelUpdated.setText("Updated just now")
        
        if let disruptionStatus = disruptionDetails.disruptionStatus {
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
        
        self.labelViewOnPhone.setText("View details on your iPhone")
        
        self.labelViewOnPhone.setHidden(false)
        self.separatorOne.setHidden(false)
        self.separatorTwo.setHidden(false)
    }
    
    func configureLoadingState() {
        if self.disruptionDetails != nil {
            self.labelUpdated.setText("Updating...")
            return
        }
        
        self.labelUpdated.setText("Updating...")
        self.labelHeader.setText("")
        self.labelStatus.setText("")
        self.imageViewStatus.setImageNamed(nil)
        self.labelViewOnPhone.setHidden(true)
        self.separatorOne.setHidden(true)
        self.separatorTwo.setHidden(true)
    }
}
