import Foundation
import Observation

@MainActor
@Observable
final class AppNavigationState {
    static let shared = AppNavigationState()

    enum Destination: Hashable {
        case serviceDetails(UUID)
        case map(UUID)
        case webInfo(UUID)
    }
    
    struct ServiceDetailsPayload {
        let serviceID: Int
        let seedService: Service?
    }

    var path: [Destination] = [] {
        didSet {
            pruneNavigationPayloads()
        }
    }
    var alertMessage: String?

    private var serviceDetailsPayloads: [UUID: ServiceDetailsPayload] = [:]
    private var mapServices: [UUID: Service] = [:]
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
        path.append(.serviceDetails(id))
    }
    
    func serviceDetails(for id: UUID) -> ServiceDetailsPayload? {
        serviceDetailsPayloads[id]
    }

    func pushMap(service: Service) {
        let id = UUID()
        mapServices[id] = service
        path.append(.map(id))
    }

    func pushWebInfo(html: String) {
        let id = UUID()
        webInfoHTML[id] = html
        path.append(.webInfo(id))
    }

    func mapService(for id: UUID) -> Service? {
        mapServices[id]
    }

    func webInfo(for id: UUID) -> String? {
        webInfoHTML[id]
    }

    private func pruneNavigationPayloads() {
        let serviceDetailsIDs = Set(
            path.compactMap { destination in
                if case .serviceDetails(let id) = destination {
                    return id
                }
                return nil
            }
        )
        serviceDetailsPayloads = serviceDetailsPayloads.filter { serviceDetailsIDs.contains($0.key) }
        
        let mapIDs = Set(
            path.compactMap { destination in
                if case .map(let id) = destination {
                    return id
                }
                return nil
            }
        )
        mapServices = mapServices.filter { mapIDs.contains($0.key) }

        let webInfoIDs = Set(
            path.compactMap { destination in
                if case .webInfo(let id) = destination {
                    return id
                }
                return nil
            }
        )
        webInfoHTML = webInfoHTML.filter { webInfoIDs.contains($0.key) }
    }
}
