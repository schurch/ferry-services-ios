//
//  TimetableTimeTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableTimeTableViewCell: UITableViewCell {

    typealias TouchedInfoButtonAction = () -> ()
    
    @IBOutlet var buttonInfo: UIButton!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelTimeCounterpart: UILabel!
    
    var touchedInfoButtonAction: TouchedInfoButtonAction?
    
    override func awakeFromNib() {
        self.buttonInfo.isHidden = true
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
    
    @IBAction func touchedButtonInfo(_ sender: UIButton) {
        touchedInfoButtonAction?()
    }
    
    override func prepareForReuse() {
        self.buttonInfo.isHidden = true
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
}
