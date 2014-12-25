//
//  ServiceDetailMapTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailMapTableViewCell: UITableViewCell {

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // don't pass hit through to mapview to allow cell to be selected
        return self
    }

}
