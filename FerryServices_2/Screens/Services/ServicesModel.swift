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
        struct Section: Identifiable {
            let id = UUID()
            
            let title: String
            let image: String?
            let services: [Service]
        }
        
        case single([Service])
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
                return Sections.Section(
                    title: serviceOperator?.name ?? "Services",
                    image: serviceOperator.flatMap({ $0.imageName }),
                    services: services
                )
            })
            
            if subscribedServices.count > 0 {
                return .multiple(
                    [Sections.Section(title: "Subscribed", image: nil, services: subscribedServices)] + servicesGroupedByOperator
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
            
            return .single(filteredServices)
        }
    }
    
}
