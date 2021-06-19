//
//  ServiceDetailWeatherCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailWeatherCell: UITableViewCell, CAAnimationDelegate {
    
    @IBOutlet weak var constraintViewSeparatorWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewWeather: UIImageView!
    @IBOutlet weak var imageViewWindDirection: UIImageView!
    @IBOutlet weak var labelConditions: UILabel!
    @IBOutlet weak var labelTemperature: UILabel!
    @IBOutlet weak var labelWindDirection: UILabel!
    @IBOutlet weak var labelWindSpeed: UILabel!
    @IBOutlet weak var viewLeftContainer: UIView!
    @IBOutlet weak var viewRightContainer: UIView!
    @IBOutlet weak var viewSeparator: UIView!
    
    var weather: LocationWeather?
    var configuring = false
    
    lazy var rotationAngle: Double? = {
        guard let windDirection = weather?.wind.deg else { return 0 }
        return windDirection + 180.0
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.constraintViewSeparatorWidth.constant = 1 / UIScreen.main.scale
    }
    
    // MARK: - Configure
    func configure(with weather: LocationWeather?, animate: Bool) {
        configuring = true
        
        self.weather = weather
        
        imageViewWindDirection.layer.removeAllAnimations()
        
        viewSeparator.isHidden = false
        viewRightContainer.isHidden = false
        viewLeftContainer.isHidden = false
        
        if let locationWeather = weather {
            labelTemperature.text = "\(Int(round(locationWeather.main.tempCelsius)))ºC"
            labelConditions.text = locationWeather.combinedWeatherDescription
            labelWindDirection.text = "\(locationWeather.wind.directionCardinal) Wind"
            imageViewWindDirection.image = UIImage(named: "Wind")
            
            if let rotationAngle = rotationAngle, animate {
                UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 5.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.imageViewWindDirection.transform = CGAffineTransform(rotationAngle: rotationAngle.toRadians())
                }, completion: { finished in
                    self.configuring = false
                })
            }
            
            labelWindSpeed.text = "\(Int(round(locationWeather.wind.speedMPH))) MPH"
            
            if let icon = locationWeather.weather[0].icon {
                imageViewWeather.image = UIImage(named: "\(icon)")
            }
        }
        else {
            labelTemperature.text = "-"
            labelConditions.text = "–"
            labelWindDirection.text = "– Wind"
            labelWindSpeed.text = "– MPH"
            imageViewWeather.image = nil
        }
        
        if !animate {
            configuring = false
        }
    }
    
    func tryAnimateWindArrow() {
        if configuring {
            return
        }
        
        if imageViewWindDirection.layer.animation(forKey: "wind") != nil {
            return
        }
        
        guard let startingAngle = rotationAngle else { return }
        
        CATransaction.begin()
        
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let values = [0, -7, 7, -5, 5, -3, 3, 0].map { (startingAngle + $0).toRadians() }
        let keyTimes = Array(0..<values.count).map { Double($0)/Double(values.count - 1) }
        
        animation.values = values
        animation.keyTimes = keyTimes as [NSNumber]?
        animation.duration = 6.0
        animation.delegate = self
        
        CATransaction.setCompletionBlock {
            self.imageViewWindDirection.layer.removeAnimation(forKey: "wind")
        }
        
        imageViewWindDirection.layer.add(animation, forKey: "wind")
        
        CATransaction.commit()
    }
}
