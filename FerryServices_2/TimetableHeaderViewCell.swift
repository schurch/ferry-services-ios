//
//  TimetableHeaderTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableHeaderViewCell: UITableViewCell {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var imageViewTransportType: UIImageView!
    
    override func awakeFromNib() {
        self.labelHeader.text = ""
    }
    
}
