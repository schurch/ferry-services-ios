//
//  ServiceDetailDisruptionsTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class DisruptionsCell: UITableViewCell {
    
    @IBOutlet weak var circleView: CircleView!
    @IBOutlet weak var labelDisruptionDetails: UILabel!
    @IBOutlet weak var labelReason: UILabel!
    @IBOutlet weak var labelReasonTitle: UILabel!
    @IBOutlet weak var reasonStackView: UIStackView!
    
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
        
        reasonStackView.isHidden = (service?.disruptionReason?.isEmpty ?? true) ? true : false
        labelReason.text = service?.disruptionReason?.capitalized
    }
}
