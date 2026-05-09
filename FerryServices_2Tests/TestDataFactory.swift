import Foundation
@testable import FerryServices_2

enum TestDataFactory {
    static func makeOperator(
        id: Int = 1,
        name: String = "Operator",
        website: String? = nil
    ) -> Service.ServiceOperator {
        Service.ServiceOperator(
            email: nil,
            facebook: nil,
            id: id,
            internationalNumber: nil,
            localNumber: nil,
            name: name,
            website: website,
            x: nil
        )
    }

    static func makeScheduledDeparture(
        departure: Date,
        arrival: Date,
        destinationID: Int,
        destinationName: String
    ) -> Service.Location.ScheduledDeparture {
        Service.Location.ScheduledDeparture(
            arrival: arrival,
            departure: departure,
            destination: .init(
                id: destinationID,
                latitude: 55.0,
                longitude: -5.0,
                name: destinationName,
                nextDeparture: nil,
                nextRailDeparture: nil,
                scheduledDepartures: nil,
                weather: nil
            ),
            notes: nil
        )
    }

    static func makeLocation(
        id: Int,
        name: String,
        nextDeparture: Service.Location.ScheduledDeparture? = nil,
        nextRailDeparture: Service.Location.RailDeparture? = nil,
        scheduledDepartures: [Service.Location.ScheduledDeparture]? = nil,
        weather: Service.Location.Weather? = nil
    ) -> Service.Location {
        Service.Location(
            id: id,
            latitude: 55.0,
            longitude: -5.0,
            name: name,
            nextDeparture: nextDeparture,
            nextRailDeparture: nextRailDeparture,
            scheduledDepartures: scheduledDepartures,
            weather: weather
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
            additionalInfo: additionalInfo,
            area: area,
            disruptionReason: nil,
            lastUpdatedDate: nil,
            locations: locations,
            _operator: serviceOperator,
            route: route,
            scheduledDeparturesAvailable: scheduledDeparturesAvailable,
            serviceId: id,
            status: status,
            timetableDocuments: nil,
            updated: Date(),
            vessels: vessels ?? []
        )
    }
}
