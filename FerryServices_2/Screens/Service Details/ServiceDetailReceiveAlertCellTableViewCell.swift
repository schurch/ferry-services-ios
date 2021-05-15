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
        switchAlert.isHidden = true
        
        activityIndicatorViewLoading.startAnimating()
        activityIndicatorViewLoading.isHidden = false
    }
    
    func configureLoadedWithSwitchOn(_ switchOn: Bool) {
        activityIndicatorViewLoading.stopAnimating()
        activityIndicatorViewLoading.isHidden = true
        
        switchAlert.isOn = switchOn
        switchAlert.isHidden = false
    }
    
}
