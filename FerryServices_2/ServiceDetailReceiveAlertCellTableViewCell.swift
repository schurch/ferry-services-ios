//
//  ServiceDetailsReceiveAlertCellTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 28/02/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailReceiveAlertCellTableViewCell: UITableViewCell {

    @IBOutlet weak var activityIndicatorViewLoading: UIActivityIndicatorView!
    @IBOutlet weak var switchAlert: UISwitch!
    @IBOutlet weak var label: UILabel!
    
    func configureLoading() {
        self.switchAlert.isHidden = true
        
        self.activityIndicatorViewLoading.startAnimating()
        self.activityIndicatorViewLoading.isHidden = false
    }
    
    func configureLoadedWithSwitchOn(_ switchOn: Bool) {
        self.activityIndicatorViewLoading.stopAnimating()
        self.activityIndicatorViewLoading.isHidden = true
        
        self.switchAlert.isOn = switchOn
        self.switchAlert.isHidden = false
    }
    
}
