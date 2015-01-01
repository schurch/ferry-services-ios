//
//  ServiceDetailNoDisruptionTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailNoDisruptionTableViewCell: UITableViewCell {
    
    @IBOutlet var buttonInfo: UIButton!
    @IBOutlet var constraintButtonWidth: NSLayoutConstraint!
    
    func configureWithDisruptionDetails(disruptionDetails: DisruptionDetails?) {
        if disruptionDetails != nil && disruptionDetails!.hasAdditionalInfo {
            showInfoButton()
        }
        else {
            hideInfoButton()
        }
    }
    
    func showInfoButton() {
        buttonInfo.hidden = false
        constraintButtonWidth.constant = 22
    }
    
    func hideInfoButton() {
        buttonInfo.hidden = true
        constraintButtonWidth.constant = 0
    }
}
