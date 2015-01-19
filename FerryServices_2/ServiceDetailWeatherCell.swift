//
//  ServiceDetailWeatherCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailWeatherCell: UITableViewCell {

    @IBOutlet weak var labelConditions: UILabel!
    @IBOutlet weak var labelWindSpeed: UILabel!
    
    // MARK: - Configure
    func configureWithWeather(weather: LocationWeather?) {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.labelConditions.preferredMaxLayoutWidth = self.labelConditions.bounds.size.width
        
        super.layoutSubviews()
    }
}
