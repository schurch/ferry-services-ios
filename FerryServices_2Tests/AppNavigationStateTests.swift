import XCTest
@testable import FerryServices_2

@MainActor
final class AppNavigationStateTests: XCTestCase {
    func testPrunesNavigationPayloadsWhenPathShrinks() {
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

        XCTAssertEqual(state.path.count, 3)

        guard case .serviceDetails(let detailsID) = state.path[0],
              case .map(let mapID) = state.path[1],
              case .webInfo(let webInfoID) = state.path[2] else {
            return XCTFail("Unexpected navigation path layout")
        }

        XCTAssertNotNil(state.serviceDetails(for: detailsID))
        XCTAssertNotNil(state.mapService(for: mapID))
        XCTAssertNotNil(state.webInfo(for: webInfoID))

        state.path = [state.path[0]]

        XCTAssertNotNil(state.serviceDetails(for: detailsID))
        XCTAssertNil(state.mapService(for: mapID))
        XCTAssertNil(state.webInfo(for: webInfoID))
    }

    func testPushServiceDetailsByIDStoresNilSeedService() {
        let state = AppNavigationState()

        state.pushServiceDetails(serviceID: 42)

        guard case .serviceDetails(let detailsID) = state.path.first else {
            return XCTFail("Expected service details destination")
        }

        let payload = state.serviceDetails(for: detailsID)
        XCTAssertEqual(payload?.serviceID, 42)
        XCTAssertNil(payload?.seedService)
    }
}
