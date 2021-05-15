//
//  ServiceStatusCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceStatusCell: UITableViewCell {
    
    static let reuseID = "serviceStatusCellReuseId"
    
    @IBOutlet weak var circleView: CircleView!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    
    func configureCellWithService(_ service: Service) {
        labelTitle.text = service.area
        labelSubtitle.text = service.route
        circleView.backgroundColor = service.status.color
    }
    
}
