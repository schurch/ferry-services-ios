//
//  TimetableDatePickerCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 17/08/17.
//  Copyright © 2017 Stefan Church. All rights reserved.
//

import Foundation
import RxSwift

class TimeTableDatePickerCell: UITableViewCell {
    
    @IBOutlet var datePicker: UIDatePicker!
    
    private(set) var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        datePicker.timeZone = Departures.timeZone
    }
}
