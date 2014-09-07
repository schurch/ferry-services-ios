//
//  TimetableDateTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableDateTableViewCell: UITableViewCell {
    
    @IBOutlet var labelSelectedDate: UILabel!
    @IBOutlet var labelDeparturesArrivals: UILabel!
    
    override func awakeFromNib() {
        self.labelSelectedDate.text = ""
        self.labelDeparturesArrivals.text = ""
    }
    
    override func prepareForReuse() {
        self.labelSelectedDate.text = ""
        self.labelDeparturesArrivals.text = ""
    }
}
