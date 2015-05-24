//
//  WeatherAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 2/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit
import FerryServicesCommon

class WeatherAPIClient {

    private struct APICLientConstants {
        static let baseURL = "http://api.openweathermap.org"
        static let cacheTimeoutSeconds = 600.0 // 10 minutes
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
    private var lastFetchTime: [String: (NSDate, LocationWeather)] = [String: (NSDate, LocationWeather)]()
    
    // MARK: - init
    init() {
        self.requestManager = AFHTTPRequestOperationManager(baseURL: NSURL(string: APICLientConstants.baseURL))
    }
    
    // MARK: - methods
    func fetchWeatherForLocation(location: Location, completion: (weather: LocationWeather?, error: NSError?) -> ()) {
        switch (location.latitude, location.longitude) {
        case let (.Some(lat), .Some(lng)):
            let requestURL = "/data/2.5/weather?lat=\(lat)&lon=\(lng)&APPID=\(APIKeys.OpenWeatherMapAPIKey)"
            
            // check if we have made a request in the last 10 minutes
            if let lastFetchForURL = self.lastFetchTime[requestURL] {
                if NSDate().timeIntervalSinceDate(lastFetchForURL.0) < APICLientConstants.cacheTimeoutSeconds {
                    completion(weather: lastFetchForURL.1, error: nil)
                    return
                }
            }
            
            self.requestManager.GET(requestURL , parameters: nil, success: { operation, responseObject in
                let json = JSONValue(responseObject)
                if (!json) {
                    let error = NSError(domain:WeatherAPIClient.clientErrorDomain, code:1, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
                    completion(weather: nil, error: error)
                    return
                }
                
                let weather = LocationWeather(data: json)
                self.lastFetchTime[requestURL] = (NSDate(), weather) // cache result
                
                completion(weather: weather, error: nil)
                
                }, failure: { operation, error in
                    completion(weather: nil, error: error)
            })
        default:
            let error = NSError(domain:WeatherAPIClient.clientErrorDomain, code:2, userInfo:[NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
            completion(weather: nil, error: error)
        }
    }
}
