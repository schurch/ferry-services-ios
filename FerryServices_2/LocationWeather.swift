//
//  Weather.swift
//  FerryServices_2
//
//  Created by Stefan Church on 4/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class Weather: Printable {
    // See http://openweathermap.org/weather-conditions for list of codes/icons/descriptions
    
    var weatherId: Double?
    var weatherGroup: String? // the group of weather (Rain, Snow, Extreme etc.)
    var weatherDescription: String? // description for weather within group
    
    // Returns a value such as 03n
    // Can be used using the URL: http://openweathermap.org/img/w/ e.g.
    // http://openweathermap.org/img/w/03n.png
    var icon: String?
    
    init(data: [String: JSONValue]) {
        
    }
    
    var description: String {
        return "WeatherID: \(self.weatherId)"
    }
}

class LocationWeather: Printable {
    
    var cityId: Int?
    var cityName: String?
    
    var dateReceieved: NSDate?
    
    var latitude: Double?
    var longitude: Double?
    
    var sunRise: NSDate?
    var sunSet: NSDate?
    
    // wind
    var windSpeed: Double? // meters per second
    var gustSpeed: Double? // meters per second
    var windDirection: Double? // degrees (meteorological)
    
    // temp
    var temp: Double? // kelvin
    var tempMin: Double? // kelvin
    var tempMax: Double? // kelvin
    
    var humidity: Double? // %
    
    //pressure
    var pressure: Double? // hpa
    var pressureGroundLevel: Double? // hpa
    var pressureSeaLevel: Double? // hpa
    
    // weather
    var weather: [Weather]?
    
    var rain: Double? // precipitation volume for last 3 hours, mm
    var snow: Double? // snow volume for last 3 hours, mm
    var clouds: Double? // cloudiness, %
    
    init (data: JSONValue) {
        self.cityId = data["id"].integer
    }
    
    var description: String {
        return "CityID: \(self.cityId)"
    }
   
}
