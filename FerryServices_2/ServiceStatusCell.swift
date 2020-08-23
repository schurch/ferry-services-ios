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
    
    func configureCellWithServiceStatus(_ serviceStatus: Service) {
        self.labelTitle.text = serviceStatus.area
        self.labelSubtitle.text = serviceStatus.route
        
        switch serviceStatus.status {
        case .normal:
            self.imageViewStatus.image = UIImage(named: "green")
        case .disrupted:
            self.imageViewStatus.image = UIImage(named: "amber")
        case .cancelled:
            self.imageViewStatus.image = UIImage(named: "red")
        case .unknown:
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
