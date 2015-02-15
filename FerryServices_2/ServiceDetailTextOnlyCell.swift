//
//  ServiceDetailTextOnlyCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailTextOnlyCell: UITableViewCell {
    
    @IBOutlet var labelText: UILabel!
    
    struct SizingCell {
        static let instance = UINib(nibName: "TextOnlyCell", bundle: nil)
            .instantiateWithOwner(nil, options: nil).first as ServiceDetailTextOnlyCell
    }
    
    class func heightWithText(text: String, tableView: UITableView) -> CGFloat {
        let cell = self.SizingCell.instance
        
        cell.labelText.text = text

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
        
        self.labelText.preferredMaxLayoutWidth = self.labelText.bounds.size.width
        
        super.layoutSubviews()
    }

}
