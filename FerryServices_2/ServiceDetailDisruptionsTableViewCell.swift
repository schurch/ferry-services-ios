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
    @IBOutlet var labelEndTime: UILabel!
    @IBOutlet var labelEndTimeTitle: UILabel!
    @IBOutlet var labelLastUpdated: UILabel!
    @IBOutlet var labelReason: UILabel!
    @IBOutlet var labelReasonTitle: UILabel!
    
    // MARK: - Configure
    func configureWithDisruptionDetails(disruptionDetails: DisruptionDetails) {
        if let status = disruptionDetails.disruptionStatus {
            if status == .SailingsCancelled {
                self.labelDisruptionDetails.text = "Sailings have been cancelled for this service"
            }
            else {
                self.labelDisruptionDetails.text = "There are disruptions with this service"
            }
        }
        
        if let disruptionStatus = disruptionDetails.disruptionStatus {
            switch disruptionStatus {
            case .SailingsAffected:
                self.imageViewDisruption.image = UIImage(named: "amber")
            case .SailingsCancelled:
                self.imageViewDisruption.image = UIImage(named: "red")
            default:
                self.imageViewDisruption.image = nil
            }
        }
        
        self.labelReason.text = disruptionDetails.reason?.capitalizedString
        
        if let date = disruptionDetails.disruptionEndDate {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
            self.labelEndTime.text = dateFormatter.stringFromDate(date)
        }
    }
}
