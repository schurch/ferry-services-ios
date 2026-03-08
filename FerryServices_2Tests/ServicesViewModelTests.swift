import Testing
@testable import FerryServices_2

@Suite
struct ServicesViewModelTests {
    @Test @MainActor
    func groupedSectionsIncludeSubscribedFirstAndSortOperatorSections() {
        let originalSubscribed = AppPreferences.shared.subscribedServiceIDs
        defer { AppPreferences.shared.subscribedServiceIDs = originalSubscribed }

        AppPreferences.shared.subscribedServiceIDs = [2]

        let operatorB = TestDataFactory.makeOperator(id: 2, name: "Beta Ferries")
        let operatorA = TestDataFactory.makeOperator(id: 1, name: "Alpha Ferries")
        let services = [
            TestDataFactory.makeService(
                id: 1,
                area: "Skye",
                route: "Route A",
                locations: [TestDataFactory.makeLocation(id: 1, name: "Port A")],
                serviceOperator: operatorB
            ),
            TestDataFactory.makeService(
                id: 2,
                area: "Arran",
                route: "Route B",
                locations: [TestDataFactory.makeLocation(id: 2, name: "Port B")],
                serviceOperator: operatorA
            )
        ]

        let viewModel = ServicesViewModel(initialServices: services)

        guard case .multiple(let sections) = viewModel.sections else {
            Issue.record("Expected grouped sections")
            return
        }

        #expect(sections.first?.title == "Subscribed")
        #expect(sections.first?.rows.map { $0.service.serviceId } == [2])

        let operatorSectionTitles = Array(sections.dropFirst().map { $0.title })
        #expect(operatorSectionTitles == ["Alpha Ferries", "Beta Ferries"])
    }

    @Test @MainActor
    func searchTextFiltersCaseInsensitivelyAcrossAreaAndRoute() {
        let services = [
            TestDataFactory.makeService(
                id: 1,
                area: "Arran",
                route: "Ardrossan - Brodick",
                locations: [TestDataFactory.makeLocation(id: 1, name: "Brodick")]
            ),
            TestDataFactory.makeService(
                id: 2,
                area: "Skye",
                route: "Mallaig - Armadale",
                locations: [TestDataFactory.makeLocation(id: 2, name: "Mallaig")]
            )
        ]

        let viewModel = ServicesViewModel(initialServices: services)
        viewModel.searchText = "ARRAN"

        guard case .single(let rows) = viewModel.sections else {
            Issue.record("Expected single search section for area query")
            return
        }
        #expect(rows.map { $0.service.serviceId } == [1])

        viewModel.searchText = "armadale"
        guard case .single(let routeRows) = viewModel.sections else {
            Issue.record("Expected single search section for route query")
            return
        }
        #expect(routeRows.map { $0.service.serviceId } == [2])
    }

    @Test @MainActor
    func rowDisruptionTextMatchesStatus() {
        let service = TestDataFactory.makeService(
            id: 1,
            status: .cancelled,
            area: "Arran",
            route: "Ardrossan - Brodick",
            locations: [TestDataFactory.makeLocation(id: 1, name: "Brodick")]
        )
        let row = ServicesViewModel.Sections.Row(id: "1", service: service)

        #expect(row.disruptionText == "Sailings Cancelled")
    }
}
