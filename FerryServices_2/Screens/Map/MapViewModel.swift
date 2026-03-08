import Foundation
import Observation

@MainActor
@Observable
final class MapViewModel {
    let service: Service

    init(service: Service) {
        self.service = service
    }

    var navigationTitle: String {
        service.route
    }
}
