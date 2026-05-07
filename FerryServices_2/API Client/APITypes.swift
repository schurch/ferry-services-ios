import Foundation

typealias Service = Components.Schemas.ServiceResponse
typealias Vessel = Components.Schemas.VesselResponse
typealias PushStatus = Components.Schemas.PushStatus

enum ServiceStatus: Int, Codable, Hashable, Sendable, CaseIterable {
    case normal = 0
    case disrupted = 1
    case cancelled = 2
    case unknown = -99
}

extension Components.Schemas.ServiceResponse {
    static let servicesCacheLocation: URL = {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return cacheDirectory.appendingPathComponent("services.json")
    }()

    static let defaultServices: [Service] = {
        do {
            guard let defaultServicesFilePath = Bundle.main.path(forResource: "services", ofType: "json") else {
                throw APIError.missingResponseData
            }
            let bundledServicesURL = URL(fileURLWithPath: defaultServicesFilePath)

            guard FileManager.default.fileExists(atPath: servicesCacheLocation.path) else {
                let bundledData = try Data(contentsOf: bundledServicesURL)
                return try APIDecoder.shared.decode([Service].self, from: bundledData)
            }

            do {
                let cachedData = try Data(contentsOf: servicesCacheLocation)
                return try APIDecoder.shared.decode([Service].self, from: cachedData)
            } catch {
                try? FileManager.default.removeItem(at: servicesCacheLocation)

                let bundledData = try Data(contentsOf: bundledServicesURL)
                return try APIDecoder.shared.decode([Service].self, from: bundledData)
            }
        } catch {
            print("Error loading default services: \(error)")
            return []
        }
    }()

    typealias Status = ServiceStatus
    typealias Location = Components.Schemas.LocationResponse
    typealias ServiceOperator = Components.Schemas.OrganisationResponse

    var `operator`: Components.Schemas.OrganisationResponse? {
        _operator
    }
}

extension Components.Schemas.LocationResponse: Identifiable {
    typealias Weather = Components.Schemas.LocationWeatherResponse
    typealias ScheduledDeparture = Components.Schemas.DepartureResponse
    typealias RailDeparture = Components.Schemas.RailDepartureResponse
}

extension Components.Schemas.DepartureResponse: Identifiable {
    typealias DepatureLocation = Components.Schemas.LocationResponse

    var id: String {
        "\(departure.timeIntervalSince1970)-\(arrival.timeIntervalSince1970)-\(destination.id)"
    }
}

extension Components.Schemas.RailDepartureResponse: Identifiable {
    var id: String {
        "\(from)-\(to)-\(departure.timeIntervalSince1970)"
    }
}

extension Components.Schemas.VesselResponse: Identifiable {
    var id: Int { mmsi }
}
