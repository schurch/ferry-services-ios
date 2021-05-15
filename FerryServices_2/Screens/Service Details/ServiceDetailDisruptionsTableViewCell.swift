//
//  ServiceDetailDisruptionsTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailDisruptionsTableViewCell: UITableViewCell {
    
    @IBOutlet var circleView: CircleView!
    @IBOutlet var labelDisruptionDetails: UILabel!
    @IBOutlet var labelReason: UILabel!
    @IBOutlet var labelReasonTitle: UILabel!
    
    func configureWithService(_ service: Service) {
        if service.status == .cancelled {
            labelDisruptionDetails.text = "Sailings have been cancelled for this service"
        } else {
            labelDisruptionDetails.text = "There are disruptions with this service"
        }

        circleView.backgroundColor = service.status.color
        labelReason.text = service.disruptionReason?.capitalized
    }
}
