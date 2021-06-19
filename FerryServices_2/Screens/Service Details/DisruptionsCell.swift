//
//  ServiceDetailDisruptionsTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class DisruptionsCell: UITableViewCell {
    
    @IBOutlet var circleView: CircleView!
    @IBOutlet var labelDisruptionDetails: UILabel!
    @IBOutlet var labelReason: UILabel!
    @IBOutlet var labelReasonTitle: UILabel!
    
    func configureWithService(_ service: Service?) {
        switch service?.status {
        case .cancelled:
            labelDisruptionDetails.text = "Sailings have been cancelled for this service"
        case .disrupted:
            labelDisruptionDetails.text = "There are disruptions with this service"
        case .normal:
            labelDisruptionDetails.text = "There are currently no disruptions with this service"
        case .unknown, nil:
            labelDisruptionDetails.text = ""
        }

        circleView.backgroundColor = service?.status.color ?? .gray
        labelReason.text = service?.disruptionReason?.capitalized
    }
}
