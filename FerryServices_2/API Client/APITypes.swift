import Foundation
import SQLite3

private let sqliteTransientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

typealias Service = Components.Schemas.ServiceResponse
typealias Vessel = Components.Schemas.VesselResponse
typealias PushStatus = Components.Schemas.PushStatus
typealias TimetableDocument = Components.Schemas.TimetableDocumentResponse

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
    typealias DepatureLocation = Components.Schemas.DepartureDestination

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
    private static let snapshotFileExtension = "sqlite3"
    private static var cachedMetadata: SnapshotMetadata?

    private static var snapshotCacheLocation: URL {
        applicationSupportDirectory.appendingPathComponent("offline-snapshot.sqlite3")
    }

    private static var metadataLocation: URL {
        applicationSupportDirectory.appendingPathComponent("offline-snapshot-metadata.json")
    }

    private static var incomingSnapshotLocation: URL {
        applicationSupportDirectory.appendingPathComponent("offline-snapshot.incoming.sqlite3")
    }

    private static var incomingMetadataLocation: URL {
        applicationSupportDirectory.appendingPathComponent("offline-snapshot-metadata.incoming.json")
    }

    private static var applicationSupportDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("Offline", isDirectory: true)
    }

    static func save(snapshotData: Data, eTag: String?) throws {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: incomingSnapshotLocation)
        try? FileManager.default.removeItem(at: incomingMetadataLocation)

        try snapshotData.write(to: incomingSnapshotLocation, options: .atomic)
        let resolvedMetadata = try snapshotMetadata(databaseAt: incomingSnapshotLocation, eTag: eTag)
        try writeMetadata(resolvedMetadata, to: incomingMetadataLocation)

        try replaceItem(at: snapshotCacheLocation, with: incomingSnapshotLocation)
        try replaceItem(at: metadataLocation, with: incomingMetadataLocation)
        cachedMetadata = try metadata()
    }

    static func eTag() throws -> String? {
        if let eTag = try metadata()?.eTag {
            return eTag
        }

        return try snapshotMetadata(
            databaseAt: activeDatabaseURL(),
            eTag: nil
        ).dataVersion
    }

    static func services() throws -> [Service] {
        try withDatabase { db in
            let serviceRows = try fetchServiceRows(in: db, serviceID: nil)
            let metadata = try metadata(for: db)
            return try serviceRows.map { serviceRow in
                try hydrateService(
                    serviceRow,
                    locations: try fetchLocations(in: db, serviceID: serviceRow.serviceID),
                    departuresByOrigin: [:],
                    generatedAt: metadata.generatedAt
                )
            }
        }
    }

    static func service(serviceID: Int, date: Date? = nil) throws -> Service {
        try withDatabase { db in
            guard let serviceRow = try fetchServiceRows(in: db, serviceID: serviceID).first else {
                throw APIError.missingResponseData
            }

            let locations = try fetchLocations(in: db, serviceID: serviceID)
            let departuresByOrigin = try fetchDeparturesByOrigin(
                in: db,
                serviceID: serviceID,
                date: date,
                locations: locations
            )
            let metadata = try metadata(for: db)

            return try hydrateService(
                serviceRow,
                locations: locations,
                departuresByOrigin: departuresByOrigin,
                generatedAt: metadata.generatedAt
            )
        }
    }

    static func timetableDocuments(serviceID: Int? = nil) throws -> [TimetableDocument] {
        []
    }

    private static func activeDatabaseURL() throws -> URL {
        guard let bundledSnapshotURL = Bundle.main.url(
            forResource: snapshotFileName,
            withExtension: snapshotFileExtension
        ) else {
            throw APIError.missingResponseData
        }

        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )

        let bundledMetadata = try snapshotMetadata(
            databaseAt: bundledSnapshotURL,
            eTag: nil
        )

        if FileManager.default.fileExists(atPath: snapshotCacheLocation.path) {
            let cachedSnapshotMetadata = try metadata()
                ?? snapshotMetadata(databaseAt: snapshotCacheLocation, eTag: nil)

            if cachedSnapshotMetadata.generatedAt >= bundledMetadata.generatedAt {
                if cachedMetadata == nil {
                    let resolvedETag = cachedSnapshotMetadata.eTag ?? cachedSnapshotMetadata.dataVersion
                    let refreshedMetadata = SnapshotMetadata(
                        eTag: resolvedETag,
                        dataVersion: cachedSnapshotMetadata.dataVersion,
                        generatedAt: cachedSnapshotMetadata.generatedAt
                    )
                    try writeMetadata(refreshedMetadata, to: metadataLocation)
                    cachedMetadata = refreshedMetadata
                }
                return snapshotCacheLocation
            }
        }

        let bootstrappedMetadata = SnapshotMetadata(
            eTag: bundledMetadata.dataVersion,
            dataVersion: bundledMetadata.dataVersion,
            generatedAt: bundledMetadata.generatedAt
        )
        try installBundledSnapshot(from: bundledSnapshotURL)
        try writeMetadata(bootstrappedMetadata, to: metadataLocation)
        cachedMetadata = bootstrappedMetadata
        return snapshotCacheLocation
    }

    private static func withDatabase<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        let databaseURL = try activeDatabaseURL()
        var db: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
            throw APIError.missingResponseData
        }
        defer { sqlite3_close(db) }
        return try body(db)
    }

    private static func hydrateService(
        _ serviceRow: ServiceRow,
        locations: [LocationRow],
        departuresByOrigin: [Int: [Service.Location.ScheduledDeparture]],
        generatedAt: Date
    ) throws -> Service {
        let hydratedLocations = locations.map { location -> Service.Location in
            let departures = departuresByOrigin[location.locationID]
            return Service.Location(
                id: location.locationID,
                name: location.name,
                latitude: location.latitude,
                longitude: location.longitude,
                scheduledDepartures: departures?.isEmpty == false ? departures : nil,
                nextDeparture: departures?.first,
                nextRailDeparture: nil,
                weather: nil
            )
        }

        return Service(
            serviceId: serviceRow.serviceID,
            area: serviceRow.area,
            route: serviceRow.route,
            status: .unknown,
            locations: hydratedLocations,
            additionalInfo: nil,
            disruptionReason: nil,
            lastUpdatedDate: nil,
            vessels: [],
            _operator: hydrateOrganisation(serviceRow.organisation),
            scheduledDeparturesAvailable: serviceRow.scheduledDeparturesAvailable,
            updated: generatedAt,
            timetableDocuments: []
        )
    }

    private static func fetchDeparturesByOrigin(
        in db: OpaquePointer,
        serviceID: Int,
        date: Date?,
        locations: [LocationRow]
    ) throws -> [Int: [Service.Location.ScheduledDeparture]] {
        guard let date else { return [:] }
        let serviceDate = date.formatted(
            Date.ISO8601FormatStyle(timeZone: Calendar.current.timeZone)
                .year()
                .month()
                .day()
        )
        let locationsByID = Dictionary(uniqueKeysWithValues: locations.map { ($0.locationID, $0) })
        let sql = """
            SELECT from_location_id, to_location_id, departure_time_utc, arrival_time_utc, notes
            FROM client_departures
            WHERE service_id = ? AND service_date = ?
            ORDER BY departure_time_utc
            """
        let rows = try prepareRows(in: db, sql: sql) { statement in
            sqlite3_bind_int64(statement, 1, sqlite3_int64(serviceID))
            sqlite3_bind_text(
                statement,
                2,
                (serviceDate as NSString).utf8String,
                -1,
                sqliteTransientDestructor
            )
        } mapRow: { statement in
            guard
                let departureString = sqliteColumnText(statement, index: 2),
                let arrivalString = sqliteColumnText(statement, index: 3)
            else {
                throw APIError.missingResponseData
            }
            let fromLocationID = Int(sqlite3_column_int64(statement, 0))
            let toLocationID = Int(sqlite3_column_int64(statement, 1))
            guard let destination = locationsByID[toLocationID] else {
                throw APIError.missingResponseData
            }

            return (
                fromLocationID,
                try Service.Location.ScheduledDeparture(
                    destination: Service.Location.ScheduledDeparture.DepatureLocation(
                        id: destination.locationID,
                        name: destination.name,
                        latitude: destination.latitude,
                        longitude: destination.longitude
                    ),
                    departure: parseUTCDate(departureString),
                    arrival: parseUTCDate(arrivalString),
                    notes: sqliteColumnText(statement, index: 4)
                )
            )
        }

        return Dictionary(grouping: rows, by: { $0.0 }).mapValues { $0.map { $0.1 } }
    }

    private static func fetchServiceRows(in db: OpaquePointer, serviceID: Int?) throws -> [ServiceRow] {
        let sql = """
            SELECT
                cs.service_id,
                cs.area,
                cs.route,
                cs.scheduled_departures_available,
                cs.organisation_id,
                cs.organisation_name,
                o.website,
                o.local_number,
                o.international_number,
                o.email,
                o.x,
                o.facebook
            FROM client_services cs
            LEFT JOIN organisations o ON o.organisation_id = cs.organisation_id
            \(serviceID == nil ? "" : "WHERE cs.service_id = ?")
            ORDER BY cs.area, cs.route
            """

        return try prepareRows(in: db, sql: sql) { statement in
            if let serviceID {
                sqlite3_bind_int64(statement, 1, sqlite3_int64(serviceID))
            }
        } mapRow: { statement in
            guard
                let area = sqliteColumnText(statement, index: 1),
                let route = sqliteColumnText(statement, index: 2),
                let organisationName = sqliteColumnText(statement, index: 5)
            else {
                throw APIError.missingResponseData
            }

            return ServiceRow(
                serviceID: Int(sqlite3_column_int64(statement, 0)),
                area: area,
                route: route,
                scheduledDeparturesAvailable: sqlite3_column_int(statement, 3) != 0,
                organisation: OrganisationRow(
                    organisationID: Int(sqlite3_column_int64(statement, 4)),
                    name: organisationName,
                    website: sqliteColumnText(statement, index: 6),
                    localNumber: sqliteColumnText(statement, index: 7),
                    internationalNumber: sqliteColumnText(statement, index: 8),
                    email: sqliteColumnText(statement, index: 9),
                    x: sqliteColumnText(statement, index: 10),
                    facebook: sqliteColumnText(statement, index: 11)
                )
            )
        }
    }

    private static func fetchLocations(in db: OpaquePointer, serviceID: Int) throws -> [LocationRow] {
        let sql = """
            SELECT location_id, name, latitude, longitude
            FROM client_service_locations
            WHERE service_id = ?
            ORDER BY display_order
            """

        return try prepareRows(in: db, sql: sql) { statement in
            sqlite3_bind_int64(statement, 1, sqlite3_int64(serviceID))
        } mapRow: { statement in
            guard let name = sqliteColumnText(statement, index: 1) else {
                throw APIError.missingResponseData
            }

            return LocationRow(
                locationID: Int(sqlite3_column_int64(statement, 0)),
                name: name,
                latitude: sqlite3_column_double(statement, 2),
                longitude: sqlite3_column_double(statement, 3)
            )
        }
    }

    private static func hydrateOrganisation(_ organisation: OrganisationRow) -> Service.ServiceOperator {
        Service.ServiceOperator(
            id: organisation.organisationID,
            name: organisation.name,
            website: organisation.website,
            localNumber: organisation.localNumber,
            internationalNumber: organisation.internationalNumber,
            email: organisation.email,
            x: organisation.x,
            facebook: organisation.facebook
        )
    }

    private static func metadata(for db: OpaquePointer) throws -> SnapshotMetadata {
        let rows = try prepareRows(in: db, sql: "SELECT key, value FROM metadata", bind: { _ in }) { statement in
            guard
                let key = sqliteColumnText(statement, index: 0),
                let value = sqliteColumnText(statement, index: 1)
            else {
                throw APIError.missingResponseData
            }
            return (key, value)
        }
        let values = Dictionary(uniqueKeysWithValues: rows)
        guard let dataVersion = values["data_version"] else {
            throw APIError.missingResponseData
        }
        let generatedAt = try values["generated_at_utc"].map(parseUTCDate) ?? Date()
        return SnapshotMetadata(
            eTag: nil,
            dataVersion: dataVersion,
            generatedAt: generatedAt
        )
    }

    private static func metadata() throws -> SnapshotMetadata? {
        if let cachedMetadata {
            return cachedMetadata
        }

        guard FileManager.default.fileExists(atPath: metadataLocation.path) else {
            return nil
        }

        let data = try Data(contentsOf: metadataLocation)
        let metadata = try APIDecoder.shared.decode(SnapshotMetadata.self, from: data)
        cachedMetadata = metadata
        return metadata
    }

    private static func snapshotMetadata(databaseAt url: URL, eTag: String?) throws -> SnapshotMetadata {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
            throw APIError.missingResponseData
        }
        defer { sqlite3_close(db) }

        let metadata = try metadata(for: db)
        return SnapshotMetadata(
            eTag: eTag,
            dataVersion: metadata.dataVersion,
            generatedAt: metadata.generatedAt
        )
    }

    private static func writeMetadata(_ metadata: SnapshotMetadata, to url: URL) throws {
        let data = try APIEncoder.shared.encode(metadata)
        try data.write(to: url, options: .atomic)
    }

    private static func replaceItem(at destinationURL: URL, with sourceURL: URL) throws {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            _ = try FileManager.default.replaceItemAt(
                destinationURL,
                withItemAt: sourceURL
            )
        } else {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func installBundledSnapshot(from bundledSnapshotURL: URL) throws {
        try? FileManager.default.removeItem(at: incomingSnapshotLocation)
        try FileManager.default.copyItem(at: bundledSnapshotURL, to: incomingSnapshotLocation)
        try replaceItem(at: snapshotCacheLocation, with: incomingSnapshotLocation)
    }

    private static func prepareRows<T>(
        in db: OpaquePointer,
        sql: String,
        bind: (OpaquePointer) throws -> Void,
        mapRow: (OpaquePointer) throws -> T
    ) throws -> [T] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw APIError.missingResponseData
        }
        defer { sqlite3_finalize(statement) }

        try bind(statement)
        var rows: [T] = []
        while true {
            let result = sqlite3_step(statement)
            switch result {
            case SQLITE_ROW:
                rows.append(try mapRow(statement))
            case SQLITE_DONE:
                return rows
            default:
                throw APIError.missingResponseData
            }
        }
    }

    private static func sqliteColumnText(_ statement: OpaquePointer, index: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: value)
    }

    private static func parseUTCDate(_ value: String) throws -> Date {
        if let date = fractionalSecondsFormatter.date(from: value) ?? internetDateFormatter.date(from: value) {
            return date
        }
        throw APIError.missingResponseData
    }

    private static let internetDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private struct ServiceRow {
        let serviceID: Int
        let area: String
        let route: String
        let scheduledDeparturesAvailable: Bool
        let organisation: OrganisationRow
    }

    private struct OrganisationRow {
        let organisationID: Int
        let name: String
        let website: String?
        let localNumber: String?
        let internationalNumber: String?
        let email: String?
        let x: String?
        let facebook: String?
    }

    private struct LocationRow {
        let locationID: Int
        let name: String
        let latitude: Double
        let longitude: Double
    }

    private struct SnapshotMetadata: Codable {
        let eTag: String?
        let dataVersion: String
        let generatedAt: Date
    }
}

@MainActor
enum TimetableDocumentMetadataStore {
    private static var cachedEntries: [String: CachedDocuments] = [:]

    private static var cacheDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("TimetableDocumentMetadata", isDirectory: true)
    }

    static func eTag(serviceID: Int?) throws -> String? {
        try cachedDocuments(serviceID: serviceID)?.eTag
    }

    static func save(
        documents: [TimetableDocument],
        eTag: String?,
        serviceID: Int?
    ) throws {
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )

        let cachedDocuments = CachedDocuments(eTag: eTag, documents: documents)
        let data = try APIEncoder.shared.encode(cachedDocuments)
        try data.write(to: cacheLocation(serviceID: serviceID), options: .atomic)
        cachedEntries[cacheKey(serviceID: serviceID)] = cachedDocuments
    }

    static func documents(serviceID: Int?) throws -> [TimetableDocument] {
        if let cachedDocuments = try cachedDocuments(serviceID: serviceID) {
            return cachedDocuments.documents
        }

        return []
    }

    private static func cachedDocuments(serviceID: Int?) throws -> CachedDocuments? {
        let key = cacheKey(serviceID: serviceID)
        if let cachedDocuments = cachedEntries[key] {
            return cachedDocuments
        }

        let location = cacheLocation(serviceID: serviceID)
        guard FileManager.default.fileExists(atPath: location.path) else {
            return nil
        }

        let data = try Data(contentsOf: location)
        let cachedDocuments = try APIDecoder.shared.decode(CachedDocuments.self, from: data)
        cachedEntries[key] = cachedDocuments
        return cachedDocuments
    }

    private static func cacheLocation(serviceID: Int?) -> URL {
        cacheDirectory.appendingPathComponent("\(cacheKey(serviceID: serviceID)).json")
    }

    private static func cacheKey(serviceID: Int?) -> String {
        serviceID.map { "service-\($0)" } ?? "all"
    }

    private struct CachedDocuments: Codable {
        let eTag: String?
        let documents: [TimetableDocument]
    }
}
