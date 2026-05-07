//
//  ServicesAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

class APIClient {
    private static let client = Client(
        serverURL: AppConfig.apiBaseURL,
        configuration: .init(dateTranscoder: FerryServicesDateTranscoder()),
        transport: URLSessionTransport()
    )
    
    static func fetchServices() async throws -> [Service] {
        let response = try await client.listServices()
        let services = try response.ok.body.applicationJsonCharsetUtf8
        cacheServices(services)
        return services
    }
        
    static func fetchService(serviceID: Int, date: Date) async throws -> Service {
        let departuresDate = date.formatted(
            Date.ISO8601FormatStyle(timeZone: Calendar.current.timeZone)
                .year()
                .month()
                .day()
        )
        let response = try await client.getService(
            path: .init(serviceID: serviceID),
            query: .init(departuresDate: departuresDate)
        )
        return try response.ok.body.applicationJsonCharsetUtf8
    }
    
    static func fetchService(serviceID: Int) async throws -> Service {
        let response = try await client.getService(path: .init(serviceID: serviceID))
        return try response.ok.body.applicationJsonCharsetUtf8
    }
    
    @discardableResult static func addService(for installationID: UUID, serviceID: Int) async throws -> [Service] {
        let response = try await client.addInstallationService(
            path: .init(installationID: installationID.uuidString),
            body: .applicationJsonCharsetUtf8(.init(serviceId: serviceID))
        )
        return try response.ok.body.applicationJsonCharsetUtf8
    }
    
    @discardableResult static func removeService(for installationID: UUID, serviceID: Int) async throws -> [Service] {
        let response = try await client.deleteInstallationService(
            path: .init(
                installationID: installationID.uuidString,
                serviceID: serviceID
            )
        )
        return try response.ok.body.applicationJsonCharsetUtf8
    }
    
    @discardableResult static func createInstallation(installationID: UUID, deviceToken: String) async throws -> [Service] {
        let response = try await client.createInstallation(
            path: .init(installationID: installationID.uuidString),
            body: .applicationJsonCharsetUtf8(
                .init(
                    deviceToken: deviceToken,
                    deviceType: .ios
                )
            )
        )
        return try response.ok.body.applicationJsonCharsetUtf8
    }
    
    static func getPushEnabledStatus(installationID: UUID) async throws -> Bool {
        let response = try await client.getPushStatus(path: .init(installationID: installationID.uuidString))
        return try response.ok.body.applicationJsonCharsetUtf8.enabled
    }
    
    static func updatePushEnabledStatus(installationID: UUID, isEnabled: Bool) async throws {
        let response = try await client.updatePushStatus(
            path: .init(installationID: installationID.uuidString),
            body: .applicationJsonCharsetUtf8(.init(enabled: isEnabled))
        )
        _ = try response.ok.body.applicationJsonCharsetUtf8
    }
    
    private static func cacheServices(_ services: [Service]) {
        do {
            let data = try APIEncoder.shared.encode(services)
            try data.write(to: Service.servicesCacheLocation)
        } catch let error {
            print("Error caching services: \(error)")
        }
    }
}

private struct FerryServicesDateTranscoder: DateTranscoder {
    func encode(_ date: Date) throws -> String {
        try ISO8601DateTranscoder.iso8601WithFractionalSeconds.encode(date)
    }

    func decode(_ dateString: String) throws -> Date {
        do {
            return try ISO8601DateTranscoder.iso8601WithFractionalSeconds.decode(dateString)
        } catch {
            return try ISO8601DateTranscoder.iso8601.decode(dateString)
        }
    }
}
