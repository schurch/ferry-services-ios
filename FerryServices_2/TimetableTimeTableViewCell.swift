//
//  TimetableTimeTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

protocol TimetableTimeTableViewCellDelegate: class {
    func didTouchTimetableInfoButtonForCell(_ cell :TimetableTimeTableViewCell)
}

class TimetableTimeTableViewCell: UITableViewCell {

    @IBOutlet var buttonInfo: UIButton!
    @IBOutlet var labelTime: UILabel!
    @IBOutlet var labelTimeCounterpart: UILabel!
    
    weak var delegate: TimetableTimeTableViewCellDelegate?
    
    override func awakeFromNib() {
        self.buttonInfo.isHidden = true
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
    
    @IBAction func touchedButtonInfo(_ sender: UIButton) {
        self.delegate?.didTouchTimetableInfoButtonForCell(self)
    }
    
    override func prepareForReuse() {
        self.buttonInfo.isHidden = true
        self.labelTime.text = ""
        self.labelTimeCounterpart.text = ""
    }
}
