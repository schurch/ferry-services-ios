//
//  Weather.swift
//  FerryServices_2
//
//  Created by Stefan Church on 4/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

struct Weather: Decodable {
    var id: Int?
    var main: String? // the group of weather (Rain, Snow, Extreme etc.)
    var description: String? // description for weather within group
    
    // Returns a value such as 03n
    // Can be used using the URL: http://openweathermap.org/img/w/ e.g.
    // http://openweathermap.org/img/w/03n.png
    var icon: String?
}

struct LocationWeather: Decodable {
    static let windDirections = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    
    struct Main: Decodable {
        var temp: Double
        
        var tempCelsius: Double {
            temp - 273.15
        }
    }
    
    struct Wind: Decodable {
        var speed: Double
        var deg: Double
        
        var speedMPH: Double {
            speed * 2.236936284
        }
        
        var directionCardinal: String {
            let i = Int((deg + 11.25) / 22.5)
            return LocationWeather.windDirections[i % 16]
        }
    }
    
    var weather: [Weather]
    var main: Main
    var wind: Wind
    
    var combinedWeatherDescription: String {
        return weather
            .compactMap { $0.description?.lowercased() }
            .joined(separator: ", ")
            .capitalizingFirstLetter()
    }
}
