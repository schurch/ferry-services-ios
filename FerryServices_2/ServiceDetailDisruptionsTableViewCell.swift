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
    
    struct SizingCell {
        static let instance = UINib(nibName: "DisruptionsCell", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! ServiceDetailDisruptionsTableViewCell
    }
    
    class func heightWithService(_ service: Service, tableView: UITableView) -> CGFloat {
        let cell = self.SizingCell.instance
        
        cell.configureWithService(service)
        cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cell.bounds.size.height)
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        
        let separatorHeight = UIScreen.main.scale / 2.0
        
        return height + separatorHeight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.setNeedsLayout()
        self.contentView.layoutSubviews()
        
        self.labelDisruptionDetails.preferredMaxLayoutWidth = self.labelDisruptionDetails.bounds.size.width
        
        super.layoutSubviews()
    }
    
    // MARK: - Configure
    func configureWithService(_ service: Service) {
        if service.status == .cancelled {
            self.labelDisruptionDetails.text = "Sailings have been cancelled for this service"
        }
        else {
            self.labelDisruptionDetails.text = "There are disruptions with this service"
        }
        
        switch service.status {
        case .disrupted:
            self.imageViewDisruption.image = UIImage(named: "amber")
        case .cancelled:
            self.imageViewDisruption.image = UIImage(named: "red")
        default:
            self.imageViewDisruption.image = nil
        }
        
        self.labelReason.text = service.disruptionReason?.capitalized
    }
}
