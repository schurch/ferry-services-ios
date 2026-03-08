import Testing
@testable import FerryServices_2

@Suite
struct AppNavigationStateTests {
    @Test @MainActor
    func prunesNavigationPayloadsWhenPathShrinks() {
        let state = AppNavigationState()
        let service = TestDataFactory.makeService(
            id: 11,
            area: "Arran",
            route: "Ardrossan - Brodick",
            locations: [TestDataFactory.makeLocation(id: 1, name: "Brodick")]
        )

        state.pushServiceDetails(service: service)
        state.pushMap(service: service)
        state.pushWebInfo(html: "<p>Info</p>")

        #expect(state.path.count == 3)

        guard case .serviceDetails(let detailsID) = state.path[0],
              case .map(let mapID) = state.path[1],
              case .webInfo(let webInfoID) = state.path[2] else {
            Issue.record("Unexpected navigation path layout")
            return
        }

        #expect(state.serviceDetails(for: detailsID) != nil)
        #expect(state.mapService(for: mapID) != nil)
        #expect(state.webInfo(for: webInfoID) != nil)

        state.path = [state.path[0]]

        #expect(state.serviceDetails(for: detailsID) != nil)
        #expect(state.mapService(for: mapID) == nil)
        #expect(state.webInfo(for: webInfoID) == nil)
    }

    @Test @MainActor
    func pushServiceDetailsByIDStoresNilSeedService() {
        let state = AppNavigationState()

        state.pushServiceDetails(serviceID: 42)

        guard case .serviceDetails(let detailsID) = state.path.first else {
            Issue.record("Expected service details destination")
            return
        }

        let payload = state.serviceDetails(for: detailsID)
        #expect(payload?.serviceID == 42)
        #expect(payload?.seedService == nil)
    }
}
