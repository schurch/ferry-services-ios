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
    @IBOutlet weak var labelWindDirection: UILabel!
    @IBOutlet weak var labelWindSpeed: UILabel!
    
    // MARK: - Configure
    func configureWithWeather(weather: LocationWeather?) {
        if let locationWeather = weather {
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
