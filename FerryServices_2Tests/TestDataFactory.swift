import Foundation
@testable import FerryServices_2

enum TestDataFactory {
    static func makeOperator(
        id: Int = 1,
        name: String = "Operator",
        website: String? = nil
    ) -> Service.ServiceOperator {
        Service.ServiceOperator(
            id: id,
            name: name,
            website: website,
            localNumber: nil,
            internationalNumber: nil,
            email: nil,
            x: nil,
            facebook: nil
        )
    }

    static func makeScheduledDeparture(
        departure: Date,
        arrival: Date,
        destinationID: Int,
        destinationName: String
    ) -> Service.Location.ScheduledDeparture {
        Service.Location.ScheduledDeparture(
            departure: departure,
            arrival: arrival,
            destination: .init(
                id: destinationID,
                name: destinationName,
                latitude: 55.0,
                longitude: -5.0
            )
        )
    }

    static func makeLocation(
        id: Int,
        name: String,
        scheduledDepartures: [Service.Location.ScheduledDeparture]? = nil
    ) -> Service.Location {
        Service.Location(
            id: id,
            name: name,
            latitude: 55.0,
            longitude: -5.0,
            weather: nil,
            scheduledDepartures: scheduledDepartures,
            nextDeparture: nil,
            nextRailDeparture: nil
        )
    }

    static func makeService(
        id: Int,
        status: Service.Status = .normal,
        area: String,
        route: String,
        additionalInfo: String? = nil,
        locations: [Service.Location],
        serviceOperator: Service.ServiceOperator? = nil,
        scheduledDeparturesAvailable: Bool? = nil,
        vessels: [Vessel]? = nil
    ) -> Service {
        Service(
            serviceId: id,
            status: status,
            area: area,
            route: route,
            disruptionReason: nil,
            lastUpdatedDate: nil,
            updated: nil,
            additionalInfo: additionalInfo,
            locations: locations,
            vessels: vessels,
            operator: serviceOperator,
            scheduledDeparturesAvailable: scheduledDeparturesAvailable
        )
    }
}
