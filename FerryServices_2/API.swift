//
//  ServicesAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation

struct Service: Decodable {
    static let defaultServices: [Service] = {
        do {
            let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json")!
            let data = try Data(contentsOf: URL(fileURLWithPath: defaultServicesFilePath))
            let services = try decoder.decode([Service].self, from: data)
            return services.sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch let error {
            fatalError("Unable to load default services: \(error)")
        }
    }()
    
    enum Status: Decodable {
        case normal
        case disrupted
        case cancelled
        case unknown
        
        init(from decoder: Decoder) throws {
            let intValue = try decoder.singleValueContainer().decode(Int.self)
            switch intValue {
            case 0:
                self = .normal
            case 1:
                self = .disrupted
            case 2:
                self = .cancelled
            default:
                self = .unknown
            }
        }
    }
    
    let id: Int
    let sortOrder: Int
    let status: Status
    let area: String
    let route: String
    let disruptionReason: String?
    let lastUpdatedDate: Date? // Time updated by Calmac
    let updated: Date? // Time updated on server
    let additionalInfo: String?
}

enum APIError: Error, LocalizedError {
    case missingResponseData
    case expectedHTTPResponse
    case badResponseCode
}

class API {
    private struct CreateInstallationBody: Encodable {
        let deviceToken: String
        let deviceType = "IOS"
    }
    
    private struct CreateInstallationServiceBody: Encodable {
        let serviceID: Int
    }
    
//    static let baseURL = URL(string: "http://localhost:3000")
    static let baseURL = URL(string: "http://scottishferryapp.com:3008")
    private static let root = "/api"
    
    static func fetchServices(completion: @escaping (Result<[Service], Error>) -> ()){
        let url = URL(string: "\(API.root)/services/", relativeTo: API.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func fetchService(serviceID: Int, completion: @escaping (Result<Service, Error>) -> ()) {
        let url = URL(string: "\(API.root)/services/\(serviceID)", relativeTo: API.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func createInstallation(installationID: UUID, deviceToken: String, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(API.root)/installations/\(installationID)", relativeTo: API.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationBody(deviceToken: deviceToken))
        send(request: request, completion: completion)
    }
    
    static func getInstallationServices(installationID: UUID, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(API.root)/installations/\(installationID)/services", relativeTo: API.baseURL)!
        send(request: URLRequest(url: url), completion: completion)
    }
    
    static func addService(for installationID: UUID, serviceID: Int, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(API.root)/installations/\(installationID)/services", relativeTo: API.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationServiceBody(serviceID: serviceID))
        send(request: request, completion: completion)
    }
    
    static func removeService(for installationID: UUID, serviceID: Int, completion: @escaping (Result<[Service], Error>) -> ()) {
        let url = URL(string: "\(API.root)/installations/\(installationID)/services/\(serviceID)", relativeTo: API.baseURL)!
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
                        let result = try decoder.decode(T.self, from: data)
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

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom { dateDecoder in
        let string = try dateDecoder.singleValueContainer().decode(String.self)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return dateFormatter.date(from: string)!
    }
    return decoder
}()
