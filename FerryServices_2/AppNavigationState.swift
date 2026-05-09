import Foundation
import Observation

@MainActor
@Observable
final class AppNavigationState {
    static let shared = AppNavigationState()

    enum Tab {
        case services
        case timetables
    }

    enum Destination: Hashable {
        case serviceDetails(UUID)
        case map(UUID)
        case timetableDocuments(UUID)
        case webInfo(UUID)
    }
    
    struct ServiceDetailsPayload {
        let serviceID: Int
        let seedService: Service?
    }

    struct TimetableDocumentsPayload {
        let serviceID: Int?
        let title: String
    }

    var selectedTab: Tab = .services
    var servicesPath: [Destination] = [] {
        didSet {
            pruneNavigationPayloads()
        }
    }
    var timetablesPath: [Destination] = [] {
        didSet {
            pruneNavigationPayloads()
        }
    }
    var alertMessage: String?

    private var serviceDetailsPayloads: [UUID: ServiceDetailsPayload] = [:]
    private var mapServices: [UUID: Service] = [:]
    private var timetableDocumentsPayloads: [UUID: TimetableDocumentsPayload] = [:]
    private var webInfoHTML: [UUID: String] = [:]
    
    func pushServiceDetails(service: Service) {
        pushServiceDetails(serviceID: service.serviceId, seedService: service)
    }
    
    func pushServiceDetails(serviceID: Int, seedService: Service? = nil) {
        let id = UUID()
        serviceDetailsPayloads[id] = ServiceDetailsPayload(
            serviceID: serviceID,
            seedService: seedService
        )
        selectedTab = .services
        servicesPath.append(.serviceDetails(id))
    }
    
    func serviceDetails(for id: UUID) -> ServiceDetailsPayload? {
        serviceDetailsPayloads[id]
    }

    func pushMap(service: Service) {
        let id = UUID()
        mapServices[id] = service
        selectedTab = .services
        servicesPath.append(.map(id))
    }

    func showTimetablesTab() {
        selectedTab = .timetables
        timetablesPath.removeAll()
    }

    func pushServiceTimetableDocuments(serviceID: Int? = nil, title: String = "Timetables") {
        let id = UUID()
        timetableDocumentsPayloads[id] = TimetableDocumentsPayload(
            serviceID: serviceID,
            title: title
        )
        selectedTab = .services
        servicesPath.append(.timetableDocuments(id))
    }

    func pushWebInfo(html: String) {
        let id = UUID()
        webInfoHTML[id] = html
        selectedTab = .services
        servicesPath.append(.webInfo(id))
    }

    func mapService(for id: UUID) -> Service? {
        mapServices[id]
    }

    func timetableDocuments(for id: UUID) -> TimetableDocumentsPayload? {
        timetableDocumentsPayloads[id]
    }

    func webInfo(for id: UUID) -> String? {
        webInfoHTML[id]
    }

    private func pruneNavigationPayloads() {
        let serviceDetailsIDs = activeIDs(for: \.serviceDetailsID)
        serviceDetailsPayloads = serviceDetailsPayloads.filter { serviceDetailsIDs.contains($0.key) }
        
        let mapIDs = activeIDs(for: \.mapID)
        mapServices = mapServices.filter { mapIDs.contains($0.key) }

        let timetableDocumentsIDs = activeIDs(for: \.timetableDocumentsID)
        timetableDocumentsPayloads = timetableDocumentsPayloads.filter {
            timetableDocumentsIDs.contains($0.key)
        }

        let webInfoIDs = activeIDs(for: \.webInfoID)
        webInfoHTML = webInfoHTML.filter { webInfoIDs.contains($0.key) }
    }
    
    private func activeIDs(for keyPath: KeyPath<Destination, UUID?>) -> Set<UUID> {
        Set((servicesPath + timetablesPath).compactMap { $0[keyPath: keyPath] })
    }
}

private extension AppNavigationState.Destination {
    var serviceDetailsID: UUID? {
        if case .serviceDetails(let id) = self { id } else { nil }
    }
    
    var mapID: UUID? {
        if case .map(let id) = self { id } else { nil }
    }

    var timetableDocumentsID: UUID? {
        if case .timetableDocuments(let id) = self { id } else { nil }
    }
    
    var webInfoID: UUID? {
        if case .webInfo(let id) = self { id } else { nil }
    }
}
