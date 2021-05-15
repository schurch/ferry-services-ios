//
//  ServiceDetailDisruptionsTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailDisruptionsTableViewCell: UITableViewCell {
    
    @IBOutlet var imageViewDisruption :UIImageView!
    @IBOutlet var labelDisruptionDetails: UILabel!
    @IBOutlet var labelReason: UILabel!
    @IBOutlet var labelReasonTitle: UILabel!
    
    func configureWithService(_ service: Service) {
        if service.status == .cancelled {
            labelDisruptionDetails.text = "Sailings have been cancelled for this service"
        } else {
            labelDisruptionDetails.text = "There are disruptions with this service"
        }
        
        switch service.status {
        case .disrupted:
            imageViewDisruption.image = UIImage(named: "amber")
        case .cancelled:
            imageViewDisruption.image = UIImage(named: "red")
        default:
            imageViewDisruption.image = nil
        }
        
        labelReason.text = service.disruptionReason?.capitalized
    }
}
