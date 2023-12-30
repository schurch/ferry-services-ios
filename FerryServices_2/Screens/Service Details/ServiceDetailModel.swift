//
//  ServiceDetailModel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/07/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import MapKit
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
class ServiceDetailModel: ObservableObject {
    
    @Published var service: Service?
    @Published var mapRect: MKMapRect
    @Published var subscribed: Bool
    @Published var loadingSubscribed: Bool = false
    @Published var showSubscribedError: Bool = false
    @Published var date: Date = Date()
    
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
    
    var registeredForNotifications: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.registeredForNotifications)
    }
    
    private var serviceID: Int
    
    init(serviceID: Int, service: Service?) {
        self.serviceID = serviceID
        self.service = service
        
        if let service {
            self.mapRect = MapViewHelpers.calculateMapRect(forLocations: service.locations)
        } else {
            self.mapRect = MKMapRect()
        }
        
        self.subscribed = subscribedIDs.contains(serviceID)
    }
    
    func updateSubscribed(subscribed: Bool) {
        Task {
            defer { loadingSubscribed = false }
            loadingSubscribed = true
            
            do {
                if subscribed {
                    try await APIClient.addService(for: Installation.id, serviceID: serviceID)
                    UserDefaults.standard.setValue(([serviceID] + subscribedIDs), forKey: UserDefaultsKeys.subscribedService)
                } else {
                    try await APIClient.removeService(for: Installation.id, serviceID: serviceID)
                    UserDefaults.standard.setValue(subscribedIDs.filter({ $0 != serviceID }), forKey: UserDefaultsKeys.subscribedService)
                }
            } catch {
                showSubscribedError = true
            }
        }
    }
    
    func fetchLatestService() async {
        do {
            let service = try await APIClient.fetchService(serviceID: serviceID, date: date)
            self.service = service
            self.mapRect = MapViewHelpers.calculateMapRect(forLocations: service.locations)
        } catch {

        }
    }
    
}

private var subscribedIDs: [Int] {
    UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? []
}
