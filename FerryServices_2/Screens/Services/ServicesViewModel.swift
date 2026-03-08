//
//  ServicesViewModel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation
import Combine

@MainActor
class ServicesViewModel: ObservableObject {
    
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
    
    @Published var sections: Sections
    @Published var searchText = ""
    
    private var services: [Service] = Service.defaultServices
    private var bag = Set<AnyCancellable>()
    
    init() {
        sections = ServicesViewModel.createSections(services: Service.defaultServices)
        $searchText
            .sink(receiveValue: { [weak self] text in
                guard let self else { return }
                self.sections = ServicesViewModel.createSections(services: self.services, searchText: text)
            })
            .store(in: &bag)
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
        if searchText.isEmpty {
            let subscribedIDs = AppPreferences.shared.subscribedServiceIDs
            let subscribedServices = services.filter({ subscribedIDs.contains($0.serviceId) })
            
            let serviceGroups = Dictionary(grouping: services, by: { $0.operator?.id ?? 0 })
            let sortedServiceGroups = serviceGroups.values
                .sorted(by: { $0.first?.operator?.name ?? "" < $1.first?.operator?.name ?? "" })
            let servicesGroupedByOperator = sortedServiceGroups.map({ services in
                let serviceOperator = services.first?.operator
                let title = serviceOperator?.name ?? NSLocalizedString("Services", comment: "")
                return Sections.Section(
                    sectionType: .services,
                    title: title,
                    imageName: serviceOperator?.imageName,
                    rows: services.map({
                        Sections.Row(
                            id: "\(title)\($0.serviceId)",
                            service: $0
                        )
                    })
                )
            })
            
            if subscribedServices.count > 0 {
                let subscribedRows = subscribedServices.map({
                    Sections.Row(
                        id: "Subscribed\($0.serviceId)",
                        service: $0
                    )
                })
                return .multiple(
                    [Sections.Section(
                        sectionType: .subscribed,
                        title: NSLocalizedString("Subscribed", comment: ""),
                        imageName: nil,
                        rows: subscribedRows
                    )] + servicesGroupedByOperator
                )
            } else {
                return .multiple(servicesGroupedByOperator)
            }
        } else {
            let filteredServices = services.filter { service in
                let areaMatch = service.area.lowercased().contains(searchText.lowercased())
                let routeMatch = service.route.lowercased().contains(searchText.lowercased())
                return areaMatch || routeMatch
            }
            
            return .single(filteredServices.map({
                Sections.Row(
                    id: String($0.serviceId),
                    service: $0
                )
            }))
        }
    }
    
}
