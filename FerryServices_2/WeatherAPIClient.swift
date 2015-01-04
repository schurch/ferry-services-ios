//
//  WeatherAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 2/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class WeatherAPIClient {
    
    private struct APICLientConstants {
        static let baseURL = "http://api.openweathermap.org"
    }
    
    // MARK: - type method
    class var clientErrorDomain: String {
        return "WeatherAPICientErrorDomain"
    }
    
    class var sharedInstance: WeatherAPIClient {
        struct Static {
            static let instance: WeatherAPIClient = WeatherAPIClient()
        }
        
        return Static.instance
    }
    
    // MARK: - properties
    private var requestManager: AFHTTPRequestOperationManager
    
    // MARK: - init
    init() {
        self.requestManager = AFHTTPRequestOperationManager(baseURL: NSURL(string: APICLientConstants.baseURL))
    }
    
    // MARK: - methods
    func fetchWeatherForLat(lat: Double, lng: Double, completion: (weather: LocationWeather?, error: NSError?) -> ()) {
        let requestURL = "/data/2.5/weather?lat=\(lat)&lon=\(lng)&APPID=\(APIKeys.OpenWeatherMapAPIKey)"
        self.requestManager.GET(requestURL , parameters: nil, success: { operation, responseObject in
            
            let json = JSONValue(responseObject)
            if (!json) {
                completion(weather: nil, error: NSError(domain:WeatherAPIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."]))
                return
            }
            
            let weather = LocationWeather(data: json)
            
            completion(weather: weather, error: nil)
            
            }, failure: { operation, error in
                completion(weather: nil, error: error)
        })
    }
}
