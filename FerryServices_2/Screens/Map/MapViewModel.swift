import Foundation

@MainActor
final class MapViewModel: ObservableObject {
    let service: Service

    init(service: Service) {
        self.service = service
    }

    var navigationTitle: String {
        service.route
    }
}
