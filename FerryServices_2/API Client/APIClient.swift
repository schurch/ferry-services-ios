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
    
//    static let baseURL = URL(string: "http://192.168.86.27:3001")
//    static let baseURL = URL(string: "http://localhost:3001")
//    private static let baseURL = URL(string: "http://test.scottishferryapp.com")
    private static let baseURL = URL(string: "https://scottishferryapp.com")
    private static let root = "/api"
    
    static func fetchServices() async throws -> [Service] {
        let url = URL(string: "\(APIClient.root)/services/", relativeTo: APIClient.baseURL)!
        return try await sendAndCacheResult(request: URLRequest(url: url))
    }
        
    static func fetchService(serviceID: Int, date: Date) async throws -> Service {
        let url = URL(
            string: "\(APIClient.root)/services/\(serviceID)",
            relativeTo: APIClient.baseURL
        )!.appending(
            queryItems: [
                URLQueryItem(
                    name: "departuresDate",
                    value: date.formatted(
                        Date.ISO8601FormatStyle(timeZone: Calendar.current.timeZone)
                            .year()
                            .month()
                            .day()
                    )
                )
            ]
        )
        
        return try await send(request: URLRequest(url: url))
    }
    
    @discardableResult static func addService(for installationID: UUID, serviceID: Int) async throws -> [Service] {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/services", relativeTo: APIClient.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationServiceBody(serviceID: serviceID))
        return try await send(request: request)
    }
    
    @discardableResult static func removeService(for installationID: UUID, serviceID: Int) async throws -> [Service] {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/services/\(serviceID)", relativeTo: APIClient.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return try await send(request: request)
    }
    
    @discardableResult static func createInstallation(installationID: UUID, deviceToken: String) async throws -> [Service] {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)", relativeTo: APIClient.baseURL)!
        let request = createRequest(with: url, body: CreateInstallationBody(deviceToken: deviceToken))
        return try await send(request: request)
    }
    
    static func getPushEnabledStatus(installationID: UUID) async throws -> Bool {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/push-status", relativeTo: APIClient.baseURL)!
        let result: PushStatus = try await send(request: URLRequest(url: url))
        return result.enabled
    }
    
    static func updatePushEnabledStatus(installationID: UUID, isEnabled: Bool) async throws {
        let url = URL(string: "\(APIClient.root)/installations/\(installationID)/push-status", relativeTo: APIClient.baseURL)!
        let request = createRequest(with: url, body: PushStatus(enabled: isEnabled))
        let _: PushStatus = try await send(request: request)
    }
    
    private static func send<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw APIError.expectedHTTPResponse
        }
        
        switch response.statusCode {
        case 200..<300:
            return try APIDecoder.shared.decode(T.self, from: data)
        default:
            throw APIError.badResponseCode
        }
    }
    
    private static func sendAndCacheResult(request: URLRequest) async throws -> [Service] {
        let services: [Service] = try await send(request: request)
        let servicesToCache = services.map {
            Service(
                serviceId: $0.serviceId,
                status: .unknown,
                area: $0.area,
                route: $0.route,
                disruptionReason: nil,
                lastUpdatedDate: nil,
                updated: nil,
                additionalInfo: nil,
                locations: $0.locations,
                vessels: [],
                operator: $0.operator
            )
        }
        
        do {
            let data = try APIEncoder.shared.encode(servicesToCache)
            try data.write(to: Service.servicesCacheLocation)
        } catch let error {
            print("Error caching services: \(error)")
        }
        
        return services
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
}
