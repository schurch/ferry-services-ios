import Foundation
import Testing
@testable import FerryServices_2

@Suite
struct ServiceDetailsViewModelTests {
    @Test @MainActor
    func scheduledDeparturesAreSortedByLocationNameAndGroupedByDestination() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        let alphaDepartures = [
            TestDataFactory.makeScheduledDeparture(
                departure: base.addingTimeInterval(2_000),
                arrival: base.addingTimeInterval(3_000),
                destinationID: 10,
                destinationName: "Campbeltown"
            ),
            TestDataFactory.makeScheduledDeparture(
                departure: base.addingTimeInterval(4_000),
                arrival: base.addingTimeInterval(5_000),
                destinationID: 20,
                destinationName: "Brodick"
            ),
            TestDataFactory.makeScheduledDeparture(
                departure: base.addingTimeInterval(4_500),
                arrival: base.addingTimeInterval(5_500),
                destinationID: 20,
                destinationName: "Brodick"
            )
        ]

        let service = TestDataFactory.makeService(
            id: 77,
            status: .disrupted,
            area: "Test Area",
            route: "Test Route",
            additionalInfo: "Service notice",
            locations: [
                TestDataFactory.makeLocation(id: 2, name: "Zeta", scheduledDepartures: [
                    TestDataFactory.makeScheduledDeparture(
                        departure: base.addingTimeInterval(1_000),
                        arrival: base.addingTimeInterval(1_500),
                        destinationID: 30,
                        destinationName: "Ardrossan"
                    )
                ]),
                TestDataFactory.makeLocation(id: 1, name: "Alpha", scheduledDepartures: alphaDepartures)
            ],
            serviceOperator: TestDataFactory.makeOperator(name: "Operator", website: "https://operator.example"),
            scheduledDeparturesAvailable: true,
            vessels: [
                Vessel(
                    mmsi: 123,
                    name: "MV Test",
                    speed: 10,
                    course: 45,
                    latitude: 55,
                    longitude: -5,
                    lastReceived: base
                )
            ]
        )

        let viewModel = ServiceDetailsViewModel(serviceID: 77, service: service)

        #expect(viewModel.sortedLocationsByName.map(\.name) == ["Alpha", "Zeta"])
        #expect(viewModel.scheduledDepartureSections.map(\.originName) == ["Alpha", "Alpha", "Zeta"])

        let alphaSections = viewModel.scheduledDepartureSections.filter { $0.originName == "Alpha" }
        #expect(alphaSections.count == 2)
        #expect(alphaSections.map(\.destinationName).sorted() == ["Brodick", "Campbeltown"])
        #expect(alphaSections.first { $0.destinationName == "Brodick" }?.rows.count == 2)

        #expect(viewModel.showScheduledDepartureWarning)
        #expect(viewModel.annotations.count == 3)
    }

    @Test @MainActor
    func scheduledDepartureInfoTextUsesAppropriateLinks() {
        let location = TestDataFactory.makeLocation(id: 1, name: "Port")
        let serviceWithLinks = TestDataFactory.makeService(
            id: 1,
            area: "Area",
            route: "Route",
            additionalInfo: "Info",
            locations: [location],
            serviceOperator: TestDataFactory.makeOperator(website: "https://operator.example")
        )
        let withLinksViewModel = ServiceDetailsViewModel(serviceID: 1, service: serviceWithLinks)

        #expect(withLinksViewModel.scheduledDepartureInfoText.contains(ServiceDetailsViewModel.Copy.moreInfoURL))
        #expect(withLinksViewModel.scheduledDepartureInfoText.contains("https://operator.example"))

        let serviceWithoutLinks = TestDataFactory.makeService(
            id: 2,
            area: "Area",
            route: "Route",
            additionalInfo: nil,
            locations: [location],
            serviceOperator: TestDataFactory.makeOperator(website: nil)
        )
        let withoutLinksViewModel = ServiceDetailsViewModel(serviceID: 2, service: serviceWithoutLinks)

        #expect(!withoutLinksViewModel.scheduledDepartureInfoText.contains(ServiceDetailsViewModel.Copy.moreInfoURL))
    }
}
