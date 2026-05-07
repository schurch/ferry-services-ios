import Foundation

typealias Service = Components.Schemas.ServiceResponse
typealias Vessel = Components.Schemas.VesselResponse
typealias PushStatus = Components.Schemas.PushStatus
typealias TimetableDocument = Components.Schemas.TimetableDocumentResponse
typealias OfflineSnapshot = Components.Schemas.OfflineSnapshot

enum ServiceStatus: Int, Codable, Hashable, Sendable, CaseIterable {
    case normal = 0
    case disrupted = 1
    case cancelled = 2
    case unknown = -99
}

extension Components.Schemas.ServiceResponse {
    @MainActor
    static var defaultServices: [Service] {
        do {
            return try OfflineSnapshotStore.services()
        } catch {
            print("Error loading default services: \(error)")
            return []
        }
    }

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

extension Components.Schemas.TimetableDocumentResponse: Identifiable {}

@MainActor
enum OfflineSnapshotStore {
    private static let snapshotFileName = "offline-snapshot"
    private static let snapshotFileExtension = "json"
    private static var cachedSnapshot: OfflineSnapshot?

    private static var snapshotCacheLocation: URL {
        applicationSupportDirectory.appendingPathComponent("offline-snapshot.json")
    }

    private static var applicationSupportDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("Offline", isDirectory: true)
    }

    static func save(snapshot: OfflineSnapshot) throws {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )
        let data = try APIEncoder.shared.encode(snapshot)
        try data.write(to: snapshotCacheLocation, options: .atomic)
        cachedSnapshot = snapshot
    }

    static func snapshot() throws -> OfflineSnapshot {
        if let cachedSnapshot {
            return cachedSnapshot
        }

        if FileManager.default.fileExists(atPath: snapshotCacheLocation.path) {
            do {
                let data = try Data(contentsOf: snapshotCacheLocation)
                let snapshot = try APIDecoder.shared.decode(OfflineSnapshot.self, from: data)
                cachedSnapshot = snapshot
                return snapshot
            } catch {
                try? FileManager.default.removeItem(at: snapshotCacheLocation)
            }
        }

        guard let bundledSnapshotURL = Bundle.main.url(
            forResource: snapshotFileName,
            withExtension: snapshotFileExtension
        ) else {
            throw APIError.missingResponseData
        }

        let data = try Data(contentsOf: bundledSnapshotURL)
        let snapshot = try APIDecoder.shared.decode(OfflineSnapshot.self, from: data)
        cachedSnapshot = snapshot
        return snapshot
    }

    static func services() throws -> [Service] {
        let snapshot = try snapshot()
        let context = HydrationContext(snapshot: snapshot)
        return snapshot.services.map { hydrateService($0, context: context, date: nil) }
    }

    static func service(serviceID: Int, date: Date? = nil) throws -> Service {
        let snapshot = try snapshot()
        guard let offlineService = snapshot.services.first(where: { $0.id == serviceID }) else {
            throw APIError.missingResponseData
        }
        return hydrateService(
            offlineService,
            context: HydrationContext(snapshot: snapshot),
            date: date
        )
    }

    static func timetableDocuments(serviceID: Int? = nil) throws -> [TimetableDocument] {
        let documents = try snapshot().timetableDocuments
        guard let serviceID else { return documents }
        return documents.filter { $0.serviceIds.contains(serviceID) }
    }

    private static func hydrateService(
        _ offlineService: Components.Schemas.OfflineService,
        context: HydrationContext,
        date: Date?
    ) -> Service {
        let departuresByOrigin = groupedDepartures(
            from: context.snapshot,
            serviceID: offlineService.id,
            date: date
        )

        let locations = offlineService.locationIds.compactMap { locationID -> Service.Location? in
            guard let offlineLocation = context.locationsByID[locationID] else { return nil }
            return hydrateLocation(
                offlineLocation,
                scheduledDepartures: departuresByOrigin[locationID] ?? [],
                locationsByID: context.locationsByID
            )
        }

        return Service(
            additionalInfo: nil,
            area: offlineService.area,
            disruptionReason: nil,
            lastUpdatedDate: nil,
            locations: locations,
            _operator: context.organisationsByID[offlineService.organisationId].map(hydrateOrganisation),
            route: offlineService.route,
            scheduledDeparturesAvailable: offlineService.scheduledDeparturesAvailable,
            serviceId: offlineService.id,
            status: .unknown,
            timetableDocuments: context.documentsByServiceID[offlineService.id],
            updated: context.snapshot.generatedAt,
            vessels: []
        )
    }

    private static func groupedDepartures(
        from snapshot: OfflineSnapshot,
        serviceID: Int,
        date: Date?
    ) -> [Int: [Components.Schemas.OfflineDeparture]] {
        guard let date else { return [:] }

        let filteredDepartures = snapshot.departures.filter { departure in
            guard departure.serviceId == serviceID else { return false }
            return Calendar.current.isDate(departure.departure, inSameDayAs: date)
        }

        return Dictionary(grouping: filteredDepartures, by: \.fromLocationId)
    }

    private static func hydrateLocation(
        _ offlineLocation: Components.Schemas.OfflineLocation,
        scheduledDepartures: [Components.Schemas.OfflineDeparture],
        locationsByID: [Int: Components.Schemas.OfflineLocation]
    ) -> Service.Location {
        let departures = scheduledDepartures.compactMap { departure -> Service.Location.ScheduledDeparture? in
            guard let destination = locationsByID[departure.toLocationId] else { return nil }
            return Service.Location.ScheduledDeparture(
                arrival: departure.arrival,
                departure: departure.departure,
                destination: hydrateLocation(destination, scheduledDepartures: [], locationsByID: locationsByID),
                notes: departure.notes
            )
        }

        return Service.Location(
            id: offlineLocation.id,
            latitude: offlineLocation.latitude,
            longitude: offlineLocation.longitude,
            name: offlineLocation.name,
            nextDeparture: departures.first,
            nextRailDeparture: nil,
            scheduledDepartures: departures.isEmpty ? nil : departures,
            weather: nil
        )
    }

    private static func hydrateOrganisation(
        _ offlineOrganisation: Components.Schemas.OfflineOrganisation
    ) -> Service.ServiceOperator {
        Service.ServiceOperator(
            email: offlineOrganisation.email,
            facebook: offlineOrganisation.facebook,
            id: offlineOrganisation.id,
            internationalNumber: offlineOrganisation.internationalNumber,
            localNumber: offlineOrganisation.localNumber,
            name: offlineOrganisation.name,
            website: offlineOrganisation.website,
            x: offlineOrganisation.x
        )
    }

    private struct HydrationContext {
        let snapshot: OfflineSnapshot
        let locationsByID: [Int: Components.Schemas.OfflineLocation]
        let organisationsByID: [Int: Components.Schemas.OfflineOrganisation]
        let documentsByServiceID: [Int: [TimetableDocument]]

        init(snapshot: OfflineSnapshot) {
            self.snapshot = snapshot
            self.locationsByID = Dictionary(uniqueKeysWithValues: snapshot.locations.map { ($0.id, $0) })
            self.organisationsByID = Dictionary(uniqueKeysWithValues: snapshot.organisations.map { ($0.id, $0) })
            self.documentsByServiceID = Dictionary(grouping: snapshot.timetableDocuments.flatMap { document in
                document.serviceIds.map { serviceID in (serviceID, document) }
            }, by: { $0.0 }).mapValues { $0.map(\.1) }
        }
    }
}
