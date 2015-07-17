//
//  WeatherAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 2/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class WeatherAPIClient {
    static let sharedInstance: WeatherAPIClient = WeatherAPIClient()
    
    static let baseURL = NSURL(string: "http://api.openweathermap.org/")
    static let cacheTimeoutSeconds = 600.0 // 10 minutes
    static let clientErrorDomain = "WeatherAPICientErrorDomain"
    
    // MARK: - properties
    private var lastFetchTime: [String: (NSDate, LocationWeather)] = [String: (NSDate, LocationWeather)]()
    
    // MARK: - methods
    func fetchWeatherForLocation(location: Location, completion: (weather: LocationWeather?, error: NSError?) -> ()) {
        switch (location.latitude, location.longitude) {
        case let (.Some(lat), .Some(lng)):
            let requestURL = "data/2.5/weather?lat=\(lat)&lon=\(lng)&APPID=\(APIKeys.OpenWeatherMapAPIKey)"
            
            // check if we have made a request in the last 10 minutes
            if let lastFetchForURL = self.lastFetchTime[requestURL] {
                if NSDate().timeIntervalSinceDate(lastFetchForURL.0) < WeatherAPIClient.cacheTimeoutSeconds {
                    completion(weather: lastFetchForURL.1, error: nil)
                    return
                }
            }
            
            let url = NSURL(string: requestURL, relativeToURL: WeatherAPIClient.baseURL)
            JSONRequester().requestWithURL(url!) { json, error in
                if error == nil {
                    if let json = json {
                        let weather = LocationWeather(data: json)
                        self.lastFetchTime[requestURL] = (NSDate(), weather) // cache result
                        dispatch_async(dispatch_get_main_queue(), {
                            completion(weather: weather, error: nil)
                        })
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(weather: nil, error: error)
                    })
                }
            }
        
        default:
            let error = NSError(domain: WeatherAPIClient.clientErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
            completion(weather: nil, error: error)
        }
    }
}
