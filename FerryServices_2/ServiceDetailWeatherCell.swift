//
//  ServiceDetailWeatherCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailWeatherCell: UITableViewCell {

    @IBOutlet weak var constraintViewSeparatorWidth: NSLayoutConstraint!
    @IBOutlet weak var labelConditions: UILabel!
    @IBOutlet weak var labelWindDirection: UILabel!
    @IBOutlet weak var labelWindSpeed: UILabel!
    @IBOutlet weak var viewSeparator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 0.5 separator width
        self.constraintViewSeparatorWidth.constant = 1 / UIScreen.mainScreen().scale
    }
    
    // MARK: - Configure
    func configureWithLocation(location: Location) {
        if let locationWeather = location.weather {
            if let weatherDescription = locationWeather.combinedWeatherDescription {
                self.labelConditions.text = weatherDescription
            }
        
            if let windDirection = locationWeather.windDirectionCardinal {
                self.labelWindDirection.text = "Wind \(windDirection)"
            }
            
            if let windSpeed = locationWeather.windSpeedMph {
                self.labelWindSpeed.text = "\(Int(round(windSpeed)))"
            }
        }
        else {
            self.labelConditions.text = "–"
            self.labelWindDirection.text = "Wind –"
            self.labelWindSpeed.text = "–"
        }
    }
}
