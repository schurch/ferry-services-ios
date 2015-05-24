//
//  ServiceDetailWeatherCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

protocol ServiceDetailWeatherCellDelegate: class {
    func didTouchReloadForWeatherCell(cell: ServiceDetailWeatherCell)
}

class ServiceDetailWeatherCell: UITableViewCell {
    
    weak var delegate: ServiceDetailWeatherCellDelegate?
    
    @IBOutlet weak var buttonReload: UIButton!
    @IBOutlet weak var constraintViewSeparatorWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewWeather: UIImageView!
    @IBOutlet weak var labelConditions: UILabel!
    @IBOutlet weak var labelTemperature: UILabel!
    @IBOutlet weak var labelWindDirection: UILabel!
    @IBOutlet weak var labelWindSpeed: UILabel!
    @IBOutlet weak var viewLeftContainer: UIView!
    @IBOutlet weak var viewRightContainer: UIView!
    @IBOutlet weak var viewSeparator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 0.5 separator width
        self.constraintViewSeparatorWidth.constant = 1 / UIScreen.mainScreen().scale
    }
    
    @IBAction func touchedButtonReload(sender: UIButton) {
        delegate?.didTouchReloadForWeatherCell(self)
    }
    
    // MARK: - Configure
    func configureWithLocation(location: Location) {
        if let error = location.weatherFetchError {
            buttonReload.hidden = false
            viewSeparator.hidden = true
            viewRightContainer.hidden = true
            viewLeftContainer.hidden = true
        }
        else {
            buttonReload.hidden = true
            viewSeparator.hidden = false
            viewRightContainer.hidden = false
            viewLeftContainer.hidden = false
            
            if let locationWeather = location.weather {
                if let temp = locationWeather.tempCelsius {
                    self.labelTemperature.text = "\(Int(round(temp)))ºC"
                }
                
                if let weatherDescription = locationWeather.combinedWeatherDescription {
                    self.labelConditions.text = weatherDescription
                }
                
                if let windDirection = locationWeather.windDirectionCardinal {
                    self.labelWindDirection.text = "Wind \(windDirection)"
                }
                
                if let windSpeed = locationWeather.windSpeedMph {
                    self.labelWindSpeed.text = "\(Int(round(windSpeed)))"
                }
                
                if let icon = locationWeather.weather?[0].icon {
                    self.imageViewWeather.image = UIImage(named: "\(icon)")
                }
            }
            else {
                self.labelTemperature.text = "-"
                self.labelConditions.text = "–"
                self.labelWindDirection.text = "Wind –"
                self.labelWindSpeed.text = "–"
                self.imageView?.image = nil
            }
        }
    }
}
