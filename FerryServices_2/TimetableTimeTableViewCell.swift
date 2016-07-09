//
//  TimetableTimeTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableTimeTableViewCell: UITableViewCell {

    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelTimeCounterpart: UILabel!
    
    override func awakeFromNib() {
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
    
    override func prepareForReuse() {
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
}
