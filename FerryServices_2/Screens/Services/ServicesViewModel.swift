//
//  ServicesViewModel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
class ServicesViewModel {
    
    enum Sections {
        struct Row: Identifiable {
            let id: String
            let service: Service
            
            var area: String { service.area }
            var route: String { service.route }
            var disruptionText: String {
                switch service.status {
                case .normal: "Normal Operations"
                case .disrupted: "Sailings Disrupted"
                case .cancelled: "Sailings Cancelled"
                case .unknown: "Unknown Status"
                }
            }
            var status: Service.Status { service.status }
        }
        
        struct Section: Identifiable {
            enum SectionType { case subscribed, services }
            
            var id: String { title }
            
            let sectionType: SectionType
            let title: String
            let imageName: String?
            let rows: [Row]

            var systemImageName: String? {
                switch sectionType {
                case .subscribed:
                    "dot.radiowaves.up.forward"
                case .services:
                    nil
                }
            }
            
            var usesAssetImage: Bool {
                sectionType == .services
            }
        }
        
        case single([Row])
        case multiple([Section])
    }
    
    var sections: Sections
    var searchText = "" {
        didSet {
            sections = ServicesViewModel.createSections(services: services, searchText: searchText)
        }
    }
    
    private var services: [Service] = Service.defaultServices
    
    init() {
        sections = ServicesViewModel.createSections(services: Service.defaultServices)
    }
    
    func fetchServices() async {
        do {
            services = try await APIClient.fetchServices()
            sections = ServicesViewModel.createSections(services: services, searchText: searchText)
        } catch {
            // Do nothing
        }
    }
    
    private static func createSections(services: [Service], searchText: String = "") -> ServicesViewModel.Sections {
        guard !searchText.isEmpty else {
            return groupedSections(services: services)
        }
        
        return searchSections(services: services, searchText: searchText)
    }
    
    private static func groupedSections(services: [Service]) -> ServicesViewModel.Sections {
        let subscribedIDs = Set(AppPreferences.shared.subscribedServiceIDs)
        let subscribedRows = services
            .filter { subscribedIDs.contains($0.serviceId) }
            .map { Sections.Row(id: "Subscribed\($0.serviceId)", service: $0) }
        
        let groupedOperatorSections = Dictionary(grouping: services, by: { $0.operator?.id ?? 0 })
            .values
            .sorted(by: { ($0.first?.operator?.name ?? "") < ($1.first?.operator?.name ?? "") })
            .map { services in
                let serviceOperator = services.first?.operator
                let title = serviceOperator?.name ?? NSLocalizedString("Services", comment: "")
                return Sections.Section(
                    sectionType: .services,
                    title: title,
                    imageName: serviceOperator?.imageName,
                    rows: services.map { Sections.Row(id: "\(title)\($0.serviceId)", service: $0) }
                )
            }
        
        guard !subscribedRows.isEmpty else {
            return .multiple(groupedOperatorSections)
        }
        
        let subscribedSection = Sections.Section(
            sectionType: .subscribed,
            title: NSLocalizedString("Subscribed", comment: ""),
            imageName: nil,
            rows: subscribedRows
        )
        return .multiple([subscribedSection] + groupedOperatorSections)
    }
    
    private static func searchSections(services: [Service], searchText: String) -> ServicesViewModel.Sections {
        let query = searchText.lowercased()
        let filteredServices = services.filter { service in
            service.area.lowercased().contains(query) || service.route.lowercased().contains(query)
        }
        
        return .single(
            filteredServices.map { Sections.Row(id: String($0.serviceId), service: $0) }
        )
    }
    
}
