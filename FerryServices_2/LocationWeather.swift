//
//  Weather.swift
//  FerryServices_2
//
//  Created by Stefan Church on 4/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON

func == (lhs: LocationWeather, rhs: LocationWeather) -> Bool {
    return lhs.cityId == rhs.cityId
}

struct Weather {
    // See http://openweathermap.org/weather-conditions for list of codes/icons/descriptions
    
    var weatherId: Int?
    var weatherGroup: String? // the group of weather (Rain, Snow, Extreme etc.)
    var weatherDescription: String? // description for weather within group
    
    // Returns a value such as 03n
    // Can be used using the URL: http://openweathermap.org/img/w/ e.g.
    // http://openweathermap.org/img/w/03n.png
    var icon: String?
    
    init(data: JSON) {
        self.weatherId = data["id"].int
        self.weatherGroup = data["main"].string
        self.weatherDescription = data["description"].string
        self.icon = data["icon"].string
    }
}

struct LocationWeather: Equatable {
    
    static let windDirections = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    
    var cityId: Int?
    var cityName: String?
    
    var dateReceieved: Date?
    
    var latitude: Double?
    var longitude: Double?
    
    var sunrise: Date?
    var sunset: Date?
    
    // wind
    var windSpeed: Double? // meters per second
    var windSpeedMph: Double? // meters mph
    var gustSpeed: Double? // meters per second
    var gustSpeedMph: Double? // meters mph
    var windDirection: Double? // degrees (meteorological)
    var windDirectionCardinal: String? // wind direction in N-S-E-W etc
    
    // temp
    var temp: Double? // kelvin
    var tempCelsius: Double? // Celsius
    var tempMin: Double? // kelvin
    var tempMax: Double? // kelvin
    
    var humidity: Double? // %
    
    //pressure
    var pressure: Double? // hpa
    var pressureGroundLevel: Double? // hpa
    var pressureSeaLevel: Double? // hpa
    
    var clouds: Double? // cloudiness, %
    
    var rain: [String: Double]? // precipitation volume for specified hours, mm
    var snow: [String: Double]? // snow volume for specified hours, mm
    
    // weather descriptions
    var weather: [Weather]?
    var combinedWeatherDescription: String?
    
    init (data: JSON) {
        self.cityId = data["id"].int
        self.cityName = data["name"].string
        
        if let dateReceivedData = data["dt"].double {
            self.dateReceieved = Date(timeIntervalSince1970: dateReceivedData)
        }
        
        self.latitude = data["coord"]["lat"].double
        self.longitude = data["coord"]["lon"].double
        
        if let sunriseData = data["sys"]["sunrise"].double {
            self.sunrise = Date(timeIntervalSince1970: sunriseData)
        }
        
        if let sunsetData = data["sys"]["sunset"].double {
            self.sunset = Date(timeIntervalSince1970: sunsetData)
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
        
//        if let rainData = data["rain"].object {
//            var rain = [String: Double]()
//            for (time, volume) in rainData {
//                rain[time] = volume.double
//            }
//            self.rain = rain
//        }
        
//        if let snowData = data["snow"].object {
//            var snow = [String: Double]()
//            for (time, volume) in snowData {
//                snow[time] = volume.double
//            }
//            self.snow = snow
//        }
        
        self.weather = data["weather"].array?.map { json in Weather(data: json) }
        
        if let weather = self.weather {
            let descriptions = weather.filter { $0.weatherDescription != nil }.map { $0.weatherDescription!.lowercased() }
            self.combinedWeatherDescription = descriptions.joined(separator: ", ").capitalizingFirstLetter()
        }
    }
}
