//
//  ServiceDetailsViewModel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/07/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

@preconcurrency import UIKit
import MapKit
import Observation
import SwiftUI

struct Annotation: Identifiable {
    enum AnnotationType { case location, vessel(course: Double) }
    
    var id: String {
        "\(coordinate.latitude)-\(coordinate.longitude)-\(type)"
    }
    
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
}

@MainActor
@Observable
class ServiceDetailsViewModel {
    struct Copy {
        static let departureDatePrefix = "Departures on "
        static let doneButtonTitle = "Done"
        static let okButtonTitle = "OK"
        static let departureDatePickerTitle = "Departure Date"
        static let errorAlertTitle = "Error"
        static let errorAlertMessage = "A problem occured. Please try again later."
        static let retryButtonTitle = "Retry"
        static let loadingTitle = "Loading..."
        static let failedToLoadMessage = "Unable to load this service right now."
        static let unknownDestination = ""
        static let travelineURL = "https://www.traveline.info"
        static let moreInfoURL = "ferryservices://more-info"
    }
    
    struct ScheduledDepartureSection: Identifiable {
        struct Row: Identifiable {
            let id: UUID
            let departureTimeText: String
            let arrivalTimeText: String
            let departureAccessibilityText: String
            let arrivalAccessibilityText: String
            let note: String?
            let isPastDeparture: Bool
        }
        
        var id: String { "\(originName)-\(destinationName)" }
        let originName: String
        let destinationName: String
        let sharedNote: String?
        let rows: [Row]
    }
    
    var service: Service?
    var mapRect: MKMapRect
    var subscribed: Bool
    var loadingSubscribed: Bool = false
    var showSubscribedError: Bool = false
    var date: Date = Date()
    var isEnabledForNotifications: Bool = false
    var hasLoadedNotificationsAuthorization: Bool = false
    var isRegisteredForNotifications: Bool = false
    var failedToLoadService: Bool = false
    
    var annotations: [Annotation] {
        guard let service else { return [] }
        
        let locations = service.locations.map({
            Annotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: $0.latitude,
                    longitude: $0.longitude
                ),
                type: .location
            )
        })
        
        let vessels = service.vessels?.map({
            Annotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: $0.latitude,
                    longitude: $0.longitude
                ),
                type: .vessel(course: $0.course ?? 0)
            )
        }) ?? []
        
        return vessels + locations
    }
    
    var sortedLocationsByName: [Service.Location] {
        (service?.locations ?? [])
            .sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }
    
    var shouldShowScheduledDepartures: Bool {
        service?.scheduledDeparturesAvailable == true
    }
    
    var selectedDateValueTitle: String {
        date.formatted(.dateTime.weekday().year().month().day())
    }
    
    var showScheduledDepartureWarning: Bool {
        guard let status = service?.status else { return false }
        return [Service.Status.cancelled, .disrupted, .unknown].contains(status)
    }
    
    var scheduledDepartureInfoText: String {
        guard let service else { return "" }
        
        let additionalInfoText: String = if !(service.additionalInfo ?? "").isEmpty {
            "[up to date information](\(Copy.moreInfoURL))"
        } else {
            "up to date information"
        }
        
        let websiteText: String = if let website = service.operator?.website, !website.isEmpty {
            "[website](\(website))"
        } else {
            "website"
        }
        
        return "Scheduled departure times provided by [Traveline](\(Copy.travelineURL)). Sailings may not be operating to the scheduled departure times. Please check the most \(additionalInfoText) from the ferry service operator or their \(websiteText) for more details."
    }
    
    var scheduledDepartureSections: [ScheduledDepartureSection] {
        let now = Date()
        let globalSharedNote = globallySharedScheduledDepartureNote
        return (service?.locations ?? [])
            .sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
            .flatMap { location in
                groupedScheduledDepartures(for: location).map { departures in
                    let notes = departures.map(\.note).map(Self.normalizedNote)
                    let sharedNote: String? = {
                        guard let firstNote = notes.first, firstNote != nil else {
                            return nil
                        }
                        if notes.allSatisfy({ $0 == firstNote }) {
                            return firstNote
                        }
                        return nil
                    }()

                    let rows = departures.map { departureInfo in
                        let departureTime = departureInfo.departure.formatted(Date.timeFormatStyle)
                        let arrivalTime = departureInfo.arrival.formatted(Date.timeFormatStyle)
                        let rowNote = Self.normalizedNote(departureInfo.note)
                        
                        return ScheduledDepartureSection.Row(
                            id: departureInfo.id,
                            departureTimeText: departureTime,
                            arrivalTimeText: arrivalTime,
                            departureAccessibilityText: "\(departureTime) departure",
                            arrivalAccessibilityText: "\(arrivalTime) arrival",
                            note: (globalSharedNote == nil && sharedNote == nil) ? rowNote : nil,
                            isPastDeparture: departureInfo.departure <= now
                        )
                    }
                    
                    return ScheduledDepartureSection(
                        originName: location.name,
                        destinationName: departures.first?.destination.name ?? Copy.unknownDestination,
                        sharedNote: globalSharedNote == nil ? sharedNote : nil,
                        rows: rows
                    )
                }
            }
    }

    var globallySharedScheduledDepartureNote: String? {
        guard let locations = service?.locations else { return nil }

        let allDepartures = locations.compactMap(\.scheduledDepartures).flatMap { $0 }
        guard !allDepartures.isEmpty else { return nil }

        let notes = allDepartures.map(\.note).map(Self.normalizedNote)
        guard let first = notes.first, first != nil else { return nil }
        return notes.allSatisfy({ $0 == first }) ? first : nil
    }
    
    var serviceOperator: Service.ServiceOperator? {
        service?.operator
    }
    
    var navigationTitle: String {
        service?.area ?? "Service"
    }
    
    var notificationSettingsURL: URL? {
        URL(string: UIApplication.openNotificationSettingsURLString)
    }
    
    private var serviceID: Int

    private static func normalizedNote(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func groupedScheduledDepartures(for location: Service.Location) -> [[Service.Location.ScheduledDeparture]] {
        guard let scheduledDepartures = location.scheduledDepartures else { return [] }
        let groups = Dictionary(grouping: scheduledDepartures, by: { $0.destination.id })
        return Array(groups.values)
            .sorted(by: { ($0.first?.departure ?? Date()) < ($1.first?.departure ?? Date()) })
    }
    
    init(serviceID: Int, service: Service?) {
        let seedService = service ?? Service.defaultServices.first(where: { $0.serviceId == serviceID })
        
        self.serviceID = serviceID
        self.service = seedService

        if let service = seedService {
            self.mapRect = MapViewHelpers.calculateMapRect(forLocations: service.locations)
        } else {
            self.mapRect = MKMapRect()
        }
        
        self.subscribed = AppPreferences.shared.subscribedServiceIDs.contains(serviceID)
        
        checkIsRegisteredForNotifications()
    }
    
    func handleDidBecomeActive() async {
        await fetchLatestService()
        await checkIsEnabledForNotifications()
    }
    
    func checkIsRegisteredForNotifications() {
        isRegisteredForNotifications = AppPreferences.shared.isRegisteredForNotifications
    }
    
    func checkIsEnabledForNotifications() async {
        nonisolated(unsafe) let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isEnabledForNotifications = settings.authorizationStatus == .authorized
        hasLoadedNotificationsAuthorization = true
    }
    
    func updateSubscribed(subscribed: Bool) {
        Task {
            defer { loadingSubscribed = false }
            loadingSubscribed = true
            
            do {
                var subscribedIDs = Set(AppPreferences.shared.subscribedServiceIDs)
                if subscribed {
                    try await APIClient.addService(for: Installation.id, serviceID: serviceID)
                    subscribedIDs.insert(serviceID)
                } else {
                    try await APIClient.removeService(for: Installation.id, serviceID: serviceID)
                    subscribedIDs.remove(serviceID)
                }
                AppPreferences.shared.subscribedServiceIDs = Array(subscribedIDs).sorted()
            } catch {
                showSubscribedError = true
            }
        }
    }
    
    func fetchLatestService() async {
        failedToLoadService = false
        
        func applyService(_ service: Service) {
            self.service = service
            self.mapRect = MapViewHelpers.calculateMapRect(forLocations: service.locations)
        }
        
        do {
            let service = try await APIClient.fetchService(serviceID: serviceID, date: date)
            applyService(service)
            return
        } catch {
            // Try the single-service endpoint without date in case date-constrained lookup fails.
            do {
                let service = try await APIClient.fetchService(serviceID: serviceID)
                applyService(service)
                return
            } catch {
                // Fallback to list endpoint so details can still render.
                do {
                    let services = try await APIClient.fetchServices()
                    if let service = services.first(where: { $0.serviceId == serviceID }) {
                        applyService(service)
                        return
                    }
                } catch {
                    // Fall through to cached/default fallback.
                }
            }
        }
        
        if let fallback = Service.defaultServices.first(where: { $0.serviceId == serviceID }) {
            applyService(fallback)
        } else {
            failedToLoadService = true
        }
    }
    
}
