//
//  ServicesAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

class APIClient {
    private struct CreateInstallationBody: Encodable {
        let deviceToken: String
        let deviceType = "IOS"
    }
    
    private struct CreateInstallationServiceBody: Encodable {
        let serviceID: Int
    }
    
//    static let baseURL = URL(string: "http://192.168.86.249:3000")
//    static let baseURL = URL(string: "http://localhost:3001")
//    private static let baseURL = URL(string: "http://test.scottishferryapp.com")
    private static let baseURL = URL(string: "https://scottishferryapp.com")
    private static let root = "/api"
    
    static func fetchServices(completion: @escaping (Result<[Service], Error>) -> ()){
        let url = URL(string: "\(APIClient.root)/services/", relativeTo: APIClient.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func fetchService(serviceID: Int, completion: @escaping (Result<Service, Error>) -> ()) {
        let url = URL(string: "\(APIClient.root)/services/\(serviceID)", relativeTo: APIClient.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func createInstallation(installationID: UUID, deviceToken: String, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)", relativeTo: APIClient.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationBody(deviceToken: deviceToken))
        send(request: request, completion: completion)
    }
    
    static func getInstallationServices(installationID: UUID, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/services", relativeTo: APIClient.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func addService(for installationID: UUID, serviceID: Int, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/services", relativeTo: APIClient.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationServiceBody(serviceID: serviceID))
        send(request: request, completion: completion)
    }
    
    static func removeService(for installationID: UUID, serviceID: Int, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/services/\(serviceID)", relativeTo: APIClient.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        send(request: request, completion: completion)
    }
    
    private static func createRequest<T: Encodable>(with url: URL, body: T) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try! encoder.encode(body)
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        return request
    }
    
    private static func send<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, Error>) -> ()) {
        URLSession.shared.dataTask(with: request) { data, response, error in
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
                        let result = try APIDecoder.shared.decode(T.self, from: data)
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
