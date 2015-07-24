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
    
    let animationDuration = 6.0
    
    weak var delegate: ServiceDetailWeatherCellDelegate?
    
    @IBOutlet weak var buttonReload: UIButton!
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
    
    var location: Location!
    var configuring = false
    
    lazy var rotationAngle: Double? = {
        if let windDirection = self.location.weather?.windDirection {
            return windDirection + 180.0
        }
        
        return 0
    }()
    
    struct SizingCell {
        static let instance = UINib(nibName: "WeatherCell", bundle: nil)
            .instantiateWithOwner(nil, options: nil).first as! ServiceDetailWeatherCell
    }
    
    class func heightWithLocation(location: Location, tableView: UITableView) -> CGFloat {
        let cell = self.SizingCell.instance
        
        cell.configureWithLocation(location, animate: false)
        cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cell.bounds.size.height)
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        
        let separatorHeight = UIScreen.mainScreen().scale / 2.0
        
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
        self.constraintViewSeparatorWidth.constant = 1 / UIScreen.mainScreen().scale
    }
    
    @IBAction func touchedButtonReload(sender: UIButton) {
        delegate?.didTouchReloadForWeatherCell(self)
    }
    
    // MARK: - Configure
    func configureWithLocation(location: Location, animate: Bool) {
        self.configuring = true
        
        self.location = location
        
        self.imageViewWindDirection.layer.removeAllAnimations()
        
        if location.weatherFetchError != nil {
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
            
            if let locationWeather = self.location.weather {
                if let temp = locationWeather.tempCelsius {
                    self.labelTemperature.text = "\(Int(round(temp)))ºC"
                }
                
                if let weatherDescription = locationWeather.combinedWeatherDescription {
                    self.labelConditions.text = weatherDescription
                }
                
                if let windDirectionCardinal = locationWeather.windDirectionCardinal {
                    self.labelWindDirection.text = "\(windDirectionCardinal) Wind"
                }
                
                self.imageViewWindDirection.image = UIImage(named: "Wind")
                
                if animate {
                    if let rotationAngle = self.rotationAngle {
                        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 5.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                            self.imageViewWindDirection.transform = CGAffineTransformMakeRotation(rotationAngle.degreesToRadians())
                            }, completion: { finished in
                                self.configuring = false
                        })
                    }
                }
                
                if let windSpeed = locationWeather.windSpeedMph {
                    self.labelWindSpeed.text = "\(Int(round(windSpeed))) MPH"
                }
                
                if let icon = locationWeather.weather?[0].icon {
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
        }
        
        if !animate {
            self.configuring = false
        }
    }
    
    func tryAnimateWindArrow() {
        if self.configuring {
            return
        }
        
        if self.imageViewWindDirection.layer.animationForKey("wind") != nil {
            return
        }
        
        if let startingAngle = self.rotationAngle {
            CATransaction.begin()
            
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            
            let values = [0, -8, 8, -4, 4, -3, 3, 0].map { angle in
                return (startingAngle + angle).degreesToRadians()
            }
            
            var keyTimes = [Double]()
            for i in 0..<values.count {
                keyTimes.append(Double(i)/Double(values.count - 1))
            }
            
            animation.values = values
            animation.keyTimes = keyTimes
            animation.duration = animationDuration
            animation.delegate = self
            
            CATransaction.setCompletionBlock {
                self.imageViewWindDirection.layer.removeAnimationForKey("wind")
            }
            
            self.imageViewWindDirection.layer.addAnimation(animation, forKey: "wind")
            
            CATransaction.commit()
        }
    }
}
