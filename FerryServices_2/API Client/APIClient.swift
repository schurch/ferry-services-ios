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
        do {
            let response = try await client.listServices()
            refreshOfflineSnapshotInBackground()
            return try response.ok.body.applicationJsonCharsetUtf8
        } catch {
            return try await OfflineSnapshotStore.services()
        }
    }
        
    static func fetchService(serviceID: Int, date: Date) async throws -> Service {
        let departuresDate = date.formatted(
            Date.ISO8601FormatStyle(timeZone: Calendar.current.timeZone)
                .year()
                .month()
                .day()
        )
        do {
            let response = try await client.getService(
                path: .init(serviceID: serviceID),
                query: .init(departuresDate: departuresDate)
            )
            refreshOfflineSnapshotInBackground()
            return try response.ok.body.applicationJsonCharsetUtf8
        } catch {
            return try await OfflineSnapshotStore.service(serviceID: serviceID, date: date)
        }
    }
    
    static func fetchService(serviceID: Int) async throws -> Service {
        do {
            let response = try await client.getService(path: .init(serviceID: serviceID))
            refreshOfflineSnapshotInBackground()
            return try response.ok.body.applicationJsonCharsetUtf8
        } catch {
            return try await OfflineSnapshotStore.service(serviceID: serviceID)
        }
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

    static func fetchTimetableDocuments(serviceID: Int? = nil) async throws -> [TimetableDocument] {
        do {
            let response = try await client.listTimetableDocuments(
                query: .init(serviceID: serviceID),
                headers: .init(ifNoneMatch: try await TimetableDocumentMetadataStore.eTag(serviceID: serviceID))
            )
            refreshOfflineSnapshotInBackground()
            switch response {
            case .ok(let ok):
                let documents = try ok.body.applicationJsonCharsetUtf8
                try await TimetableDocumentMetadataStore.save(
                    documents: documents,
                    eTag: ok.headers.eTag,
                    serviceID: serviceID
                )
                return documents
            case .undocumented(statusCode: 304, _):
                return try await TimetableDocumentMetadataStore.documents(serviceID: serviceID)
            default:
                _ = try response.ok
                throw APIError.badResponseCode
            }
        } catch {
            return try await TimetableDocumentMetadataStore.documents(serviceID: serviceID)
        }
    }

    static func localTimetableDocumentURL(for document: TimetableDocument) -> URL? {
        TimetableDocumentStore.localURL(for: document)
    }

    static func deleteLocalTimetableDocument(_ document: TimetableDocument) throws {
        try TimetableDocumentStore.delete(document: document)
    }

    static func downloadTimetableDocument(_ document: TimetableDocument) async throws -> URL {
        try await TimetableDocumentStore.download(document: document)
    }

    private static func refreshOfflineSnapshotInBackground() {
        Task.detached {
            do {
                var request = URLRequest(
                    url: AppConfig.apiBaseURL
                        .appendingPathComponent("api")
                        .appendingPathComponent("offline")
                        .appendingPathComponent("snapshot.sqlite3")
                )
                if let eTag = try await OfflineSnapshotStore.eTag() {
                    request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
                }

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let response = response as? HTTPURLResponse else { return }

                switch response.statusCode {
                case 200:
                    try await OfflineSnapshotStore.save(
                        snapshotData: data,
                        eTag: response.value(forHTTPHeaderField: "ETag")
                    )
                case 304:
                    break
                default:
                    break
                }
            } catch {
                // Best-effort cache refresh.
            }
        }
    }
}

private enum TimetableDocumentStore {
    private static var documentsDirectory: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("TimetableDocuments", isDirectory: true)
    }

    static func localURL(for document: TimetableDocument) -> URL? {
        let url = fileURL(for: document)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func download(document: TimetableDocument) async throws -> URL {
        if let localURL = localURL(for: document) {
            return localURL
        }

        guard let remoteURL = URL(string: document.sourceUrl) else {
            throw APIError.invalidURL
        }

        try FileManager.default.createDirectory(
            at: documentsDirectory,
            withIntermediateDirectories: true
        )

        let (temporaryURL, _) = try await URLSession.shared.download(from: remoteURL)
        let destinationURL = fileURL(for: document)
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    static func delete(document: TimetableDocument) throws {
        let destinationURL = fileURL(for: document)
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            return
        }

        try FileManager.default.removeItem(at: destinationURL)
    }

    private static func fileURL(for document: TimetableDocument) -> URL {
        let extensionValue = URL(string: document.sourceUrl)?.pathExtension
        let pathExtension = (extensionValue?.isEmpty == false ? extensionValue : nil)
            ?? (document.contentType == "application/pdf" ? "pdf" : "download")
        let baseName = sanitizedFilenameBase(for: document)
        return documentsDirectory.appendingPathComponent(
            "\(baseName).\(pathExtension)"
        )
    }

    private static func sanitizedFilenameBase(for document: TimetableDocument) -> String {
        var title = document.title.trimmingCharacters(in: .whitespacesAndNewlines)

        let redundantPrefixes = [
            "\(document.organisationName): ",
            "Caledonian MacBrayne: "
        ]

        for prefix in redundantPrefixes where title.hasPrefix(prefix) {
            title.removeFirst(prefix.count)
            break
        }

        let printablePrefix = "Download a printable "
        if title.localizedLowercase.hasPrefix(printablePrefix.localizedLowercase) {
            title.removeFirst(printablePrefix.count)
        }

        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitizedTitle = title
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fallback = sanitizedTitle.isEmpty ? "Timetable" : sanitizedTitle
        return "\(fallback)-\(document.id)"
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
