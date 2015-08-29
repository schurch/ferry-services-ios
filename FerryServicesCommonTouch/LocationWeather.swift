//
//  Weather.swift
//  FerryServices_2
//
//  Created by Stefan Church on 4/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit
import Foundation

public func == (lhs: LocationWeather, rhs: LocationWeather) -> Bool {
    return lhs.cityId == rhs.cityId
}

public struct Weather {
    // See http://openweathermap.org/weather-conditions for list of codes/icons/descriptions
    
    public var weatherId: Int?
    public var weatherGroup: String? // the group of weather (Rain, Snow, Extreme etc.)
    public var weatherDescription: String? // description for weather within group
    
    // Returns a value such as 03n
    // Can be used using the URL: http://openweathermap.org/img/w/ e.g.
    // http://openweathermap.org/img/w/03n.png
    public var icon: String?
    
    init(data: JSONValue) {
        self.weatherId = data["id"].integer
        self.weatherGroup = data["main"].string
        self.weatherDescription = data["description"].string
        self.icon = data["icon"].string
    }
}

public struct LocationWeather: Equatable {
    
    static let windDirections = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    
    public var cityId: Int?
    public var cityName: String?
    
    public var dateReceieved: NSDate?
    
    public var latitude: Double?
    public var longitude: Double?
    
    public var sunrise: NSDate?
    public var sunset: NSDate?
    
    // wind
    public var windSpeed: Double? // meters per second
    public var windSpeedMph: Double? // meters mph
    public var gustSpeed: Double? // meters per second
    public var gustSpeedMph: Double? // meters mph
    public var windDirection: Double? // degrees (meteorological)
    public var windDirectionCardinal: String? // wind direction in N-S-E-W etc
    
    // temp
    public var temp: Double? // kelvin
    public var tempCelsius: Double? // Celsius
    public var tempMin: Double? // kelvin
    public var tempMax: Double? // kelvin
    
    public var humidity: Double? // %
    
    //pressure
    public var pressure: Double? // hpa
    public var pressureGroundLevel: Double? // hpa
    public var pressureSeaLevel: Double? // hpa
    
    public var clouds: Double? // cloudiness, %
    
    public var rain: [String: Double]? // precipitation volume for specified hours, mm
    public var snow: [String: Double]? // snow volume for specified hours, mm
    
    // weather descriptions
    public var weather: [Weather]?
    public var combinedWeatherDescription: String?
    
    init (data: JSONValue) {
        self.cityId = data["id"].integer
        self.cityName = data["name"].string
        
        if let dateReceivedData = data["dt"].double {
            self.dateReceieved = NSDate(timeIntervalSince1970: dateReceivedData)
        }
        
        self.latitude = data["coord"]["lat"].double
        self.longitude = data["coord"]["lon"].double
        
        if let sunriseData = data["sys"]["sunrise"].double {
            self.sunrise = NSDate(timeIntervalSince1970: sunriseData)
        }
        
        if let sunsetData = data["sys"]["sunset"].double {
            self.sunset = NSDate(timeIntervalSince1970: sunsetData)
        }
        
        self.windSpeed = data["wind"]["speed"].double
        if let windSpeed = self.windSpeed {
            self.windSpeedMph = windSpeed * 2.236936284
        }
        
        self.gustSpeed = data["wind"]["gust"].double
        if let gustSpeed = self.gustSpeed {
            self.gustSpeedMph = gustSpeed * 2.236936284
        }
        
        self.windDirection = data["wind"]["deg"].double
        if let windDirection = self.windDirection {
            let i = Int((windDirection + 11.25) / 22.5)
            self.windDirectionCardinal = LocationWeather.windDirections[i % 16]
        }
        
        self.temp = data["main"]["temp"].double
        if let temp = self.temp {
            self.tempCelsius = temp - 273.15
        }
        
        self.tempMax = data["main"]["temp_max"].double
        self.tempMin = data["main"]["temp_min"].double
        
        self.humidity = data["main"]["humidity"].double
        
        self.pressure = data["main"]["pressure"].double
        self.pressureGroundLevel = data["main"]["grnd_level"].double
        self.pressureSeaLevel = data["main"]["sea_level"].double
        
        self.clouds = data["clouds"]["all"].double
        
        if let rainData = data["rain"].object {
            var rain = [String: Double]()
            for (time, volume) in rainData {
                rain[time] = volume.double
            }
            self.rain = rain
        }
        
        if let snowData = data["snow"].object {
            var snow = [String: Double]()
            for (time, volume) in snowData {
                snow[time] = volume.double
            }
            self.snow = snow
        }
        
        self.weather = data["weather"].array?.map { json in Weather(data: json) }
        
        if let weather = self.weather {
            let descriptions = weather.filter { $0.weatherDescription != nil }.map { $0.weatherDescription!.lowercaseString }
            
            var combined =  descriptions.joinWithSeparator(", ")
            combined.replaceRange(combined.startIndex...combined.startIndex, with: String(combined[combined.startIndex]).capitalizedString)
            
            self.combinedWeatherDescription = combined
        }
    }
}
