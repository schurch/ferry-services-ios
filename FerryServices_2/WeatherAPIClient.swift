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
    
    private static let error = NSError(domain: WeatherAPIClient.clientErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
    
    // MARK: - properties
    fileprivate var lastFetchTime: [String: (Date, LocationWeather)] = [String: (Date, LocationWeather)]()
    
    // MARK: - methods
    func fetchWeatherForLocation(_ location: Service.Location, completion: @escaping (Result<LocationWeather, Error>) -> ()) {
        let requestURL = "data/2.5/weather?lat=\(location.latitude)&lon=\(location.longitude)&APPID=\(APIKeys.openWeatherMapAPIKey)"
        
        // check if we have made a request in the last 10 minutes
        if let lastFetchForURL = self.lastFetchTime[requestURL] {
            if Date().timeIntervalSince(lastFetchForURL.0) < WeatherAPIClient.cacheTimeoutSeconds {
                completion(.success(lastFetchForURL.1))
                return
            }
        }
        
        let url = URL(string: requestURL, relativeTo: WeatherAPIClient.baseURL)!
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(APIError.expectedHTTPResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.missingResponseData))
                    return
                }
                
                switch response.statusCode {
                case 200..<300:
                    do {
                        let result = try JSONDecoder().decode(LocationWeather.self, from: data)
                        self.lastFetchTime[requestURL] = (Date(), result) // cache result
                        completion(.success(result))
                    } catch {
                        completion(.failure(error))
                    }
                default:
                    completion(.failure(APIError.badResponseCode))
                }
            }
        }.resume()
    }
}
