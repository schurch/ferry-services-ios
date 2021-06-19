//
//  ServiceDetailNoDisruptionTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class NoDisruptionCell: UITableViewCell {
    
    @IBOutlet weak var buttonInfo: UIButton!
    @IBOutlet weak var constraintButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var labelNoDisruptions: UILabel!
    @IBOutlet weak var circleView: CircleView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        circleView.backgroundColor = UIColor(named: "Green")
    }
    
    func configureWithService(_ service: Service?) {
        if service?.additionalInfo != nil {
            showInfoButton()
        } else {
            hideInfoButton()
        }
    }
    
    func showInfoButton() {
        buttonInfo.isHidden = false
        constraintButtonWidth.constant = 22
    }
    
    func hideInfoButton() {
        buttonInfo.isHidden = true
        constraintButtonWidth.constant = 0
    }
}
