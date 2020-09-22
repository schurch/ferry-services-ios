//
//  ServiceDetailWeatherCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class ServiceDetailWeatherCell: UITableViewCell, CAAnimationDelegate {
    
    let animationDuration = 6.0

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
        if let windDirection = weather?.wind.deg {
            return windDirection + 180.0
        }
        
        return 0
    }()
    
    struct SizingCell {
        static let instance = UINib(nibName: "WeatherCell", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! ServiceDetailWeatherCell
    }
    
    class func height(for weather: LocationWeather?, tableView: UITableView) -> CGFloat {
        let cell = self.SizingCell.instance
        
        cell.configure(with: weather, animate: false)
        cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cell.bounds.size.height)
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        
        let separatorHeight = UIScreen.main.scale / 2.0
        
        return height + separatorHeight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.setNeedsLayout()
        self.contentView.layoutSubviews()
        
        self.labelConditions.preferredMaxLayoutWidth = self.labelConditions.bounds.size.width
        
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 0.5 separator width
        self.constraintViewSeparatorWidth.constant = 1 / UIScreen.main.scale
    }
    
    // MARK: - Configure
    func configure(with weather: LocationWeather?, animate: Bool) {
        self.configuring = true
        
        self.weather = weather
        
        self.imageViewWindDirection.layer.removeAllAnimations()
        
        viewSeparator.isHidden = false
        viewRightContainer.isHidden = false
        viewLeftContainer.isHidden = false
        
        if let locationWeather = weather {
            self.labelTemperature.text = "\(Int(round(locationWeather.main.tempCelsius)))ºC"
            self.labelConditions.text = locationWeather.combinedWeatherDescription
            self.labelWindDirection.text = "\(locationWeather.wind.directionCardinal) Wind"
            self.imageViewWindDirection.image = UIImage(named: "Wind")
            
            if animate {
                if let rotationAngle = self.rotationAngle {
                    UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 5.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.imageViewWindDirection.transform = CGAffineTransform(rotationAngle: rotationAngle.toRadians())
                    }, completion: { finished in
                        self.configuring = false
                    })
                }
            }
            
            self.labelWindSpeed.text = "\(Int(round(locationWeather.wind.speedMPH))) MPH"
            
            if let icon = locationWeather.weather[0].icon {
                self.imageViewWeather.image = UIImage(named: "\(icon)")
            }
        }
        else {
            self.labelTemperature.text = "-"
            self.labelConditions.text = "–"
            self.labelWindDirection.text = "– Wind"
            self.labelWindSpeed.text = "– MPH"
            self.imageViewWeather.image = nil
        }
        
        if !animate {
            self.configuring = false
        }
    }
    
    func tryAnimateWindArrow() {
        if self.configuring {
            return
        }
        
        if self.imageViewWindDirection.layer.animation(forKey: "wind") != nil {
            return
        }
        
        if let startingAngle = self.rotationAngle {
            CATransaction.begin()
            
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            
            let values = [0, -7, 7, -5, 5, -3, 3, 0].map { angle in
                return (startingAngle + angle).toRadians()
            }
            
            var keyTimes = [Double]()
            for i in 0..<values.count {
                keyTimes.append(Double(i)/Double(values.count - 1))
            }
            
            animation.values = values
            animation.keyTimes = keyTimes as [NSNumber]?
            animation.duration = animationDuration
            animation.delegate = self
            
            CATransaction.setCompletionBlock {
                self.imageViewWindDirection.layer.removeAnimation(forKey: "wind")
            }
            
            self.imageViewWindDirection.layer.add(animation, forKey: "wind")
            
            CATransaction.commit()
        }
    }
}
