//
//  ServiceDetailNoDisruptionTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailNoDisruptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var buttonInfo: UIButton!
    @IBOutlet weak var constraintButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var labelNoDisruptions: UILabel!
    
    struct SizingCell {
        static let instance = UINib(nibName: "NoDisruptionsCell", bundle: nil)
            .instantiateWithOwner(nil, options: nil).first as! ServiceDetailNoDisruptionTableViewCell
    }
    
    class func heightWithDisruptionDetails(disruptionDetails: DisruptionDetails?, tableView: UITableView) -> CGFloat {
        let cell = self.SizingCell.instance
        
        cell.configureWithDisruptionDetails(disruptionDetails)
        cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cell.bounds.size.height)
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        
        let separatorHeight = UIScreen.mainScreen().scale / 2.0
        
        return height + separatorHeight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.setNeedsLayout()
        self.contentView.layoutSubviews()
        
        self.labelNoDisruptions.preferredMaxLayoutWidth = self.labelNoDisruptions.bounds.size.width
        
        super.layoutSubviews()
    }
    
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
