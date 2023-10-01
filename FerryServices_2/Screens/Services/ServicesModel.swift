//
//  ServicesModel.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation
import Combine

@MainActor
class ServicesModel: ObservableObject {
    
    enum Sections {
        struct Row: Identifiable {
            let id: String
            let service: Service
        }
        
        struct Section: Identifiable {
            var id: String { title }
            
            let title: String
            let rows: [Row]
        }
        
        case single([Row])
        case multiple([Section])
    }
    
    @Published var sections: Sections
    @Published var searchText = ""
    
    private var services: [Service] = Service.defaultServices
    private var bag = Set<AnyCancellable>()
    
    init() {
        sections = ServicesModel.createSections(services: Service.defaultServices)
        $searchText
            .sink(receiveValue: { [weak self] text in
                guard let self else { return }
                self.sections = ServicesModel.createSections(services: self.services, searchText: text)
            })
            .store(in: &bag)
    }
    
    func fetchServices() async {
        do {
            services = try await APIClient.fetchServices()
            sections = ServicesModel.createSections(services: services, searchText: searchText)
        } catch {
            // Do nothing
        }
    }
    
    private static func createSections(services: [Service], searchText: String = "") -> ServicesModel.Sections {
        if searchText.isEmpty {
            let subscribedIDs = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? []
            let subscribedServices = services.filter({ subscribedIDs.contains($0.serviceId) })
            
            let serviceGroups = Dictionary(grouping: services, by: { $0.operator?.id ?? 0 })
            let sortedServiceGroups = serviceGroups.values
                .sorted(by: { $0.first?.operator?.name ?? "" < $1.first?.operator?.name ?? "" })
            let servicesGroupedByOperator = sortedServiceGroups.map({ services in
                let serviceOperator = services.first?.operator
                let title = serviceOperator?.name ?? NSLocalizedString("Services", comment: "")
                return Sections.Section(
                    title: title,
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
                        title: NSLocalizedString("Subscribed", comment: ""),
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
