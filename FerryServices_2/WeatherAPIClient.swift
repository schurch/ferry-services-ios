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
    
    static let baseURL = URL(string: "http://api.openweathermap.org/")
    static let cacheTimeoutSeconds = 600.0 // 10 minutes
    static let clientErrorDomain = "WeatherAPICientErrorDomain"
    
    // MARK: - properties
    fileprivate var lastFetchTime: [String: (Date, LocationWeather)] = [String: (Date, LocationWeather)]()
    
    // MARK: - methods
    func fetchWeatherForLocation(_ location: Location, completion: @escaping (_ weather: LocationWeather?, _ error: NSError?) -> ()) {
        switch (location.latitude, location.longitude) {
        case let (.some(lat), .some(lng)):
            let requestURL = "data/2.5/weather?lat=\(lat)&lon=\(lng)&APPID=\(APIKeys.OpenWeatherMapAPIKey)"
            
            // check if we have made a request in the last 10 minutes
            if let lastFetchForURL = self.lastFetchTime[requestURL] {
                if Date().timeIntervalSince(lastFetchForURL.0) < WeatherAPIClient.cacheTimeoutSeconds {
                    completion(lastFetchForURL.1, nil)
                    return
                }
            }
            
            let url = URL(string: requestURL, relativeTo: WeatherAPIClient.baseURL)
            JSONRequester().requestWithURL(url!) { json, error in
                if error == nil {
                    if let json = json {
                        let weather = LocationWeather(data: json)
                        self.lastFetchTime[requestURL] = (Date(), weather) // cache result
                        DispatchQueue.main.async(execute: {
                            completion(weather, nil)
                        })
                    }
                }
                else {
                    DispatchQueue.main.async(execute: {
                        completion(nil, error)
                    })
                }
            }
        
        default:
            let error = NSError(domain: WeatherAPIClient.clientErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
            completion(nil, error)
        }
    }
}
