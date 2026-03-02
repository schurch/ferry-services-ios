import Foundation

@MainActor
final class AppNavigationState: ObservableObject {
    static let shared = AppNavigationState()

    enum Destination: Hashable {
        case serviceDetails(Int)
        case map(UUID)
        case webInfo(UUID)
    }

    @Published var path: [Destination] = [] {
        didSet {
            pruneNavigationPayloads()
        }
    }
    @Published var alertMessage: String?

    private var mapServices: [UUID: Service] = [:]
    private var webInfoHTML: [UUID: String] = [:]

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
