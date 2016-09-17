//
//  ServiceStatusCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceStatusCell: UITableViewCell {
    
    @IBOutlet weak var constraintTitleLeadingSpace: NSLayoutConstraint!
    @IBOutlet weak var imageViewStatus: UIImageView!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    
    func configureCellWithServiceStatus(_ serviceStatus: ServiceStatus) {
        self.labelTitle.text = serviceStatus.area
        self.labelSubtitle.text = serviceStatus.route
        
        if let disruptionStatus = serviceStatus.disruptionStatus {
            switch disruptionStatus {
            case .normal:
                self.imageViewStatus.image = UIImage(named: "green")
            case .sailingsAffected:
                self.imageViewStatus.image = UIImage(named: "amber")
            case .sailingsCancelled:
                self.imageViewStatus.image = UIImage(named: "red")
            case .unknown:
                self.imageViewStatus.image = UIImage(named: "grey")
            }
        }
        else {
            self.imageViewStatus.image = UIImage(named: "grey")
        }
        
        if self.imageViewStatus.image == nil {
            self.constraintTitleLeadingSpace.constant = self.layoutMargins.left
        }
        else {
            self.constraintTitleLeadingSpace.constant = 42
        }
    }
    
}
