//
//  VesselAnnotation.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/05/22.
//  Copyright © 2022 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

class VesselAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    @objc dynamic var title: String?
    @objc dynamic var subtitle: String?
    var course: Double?
    
    init(vessel: Vessel) {
        self.coordinate = CLLocationCoordinate2D(
            latitude: vessel.latitude,
            longitude: vessel.longitude
        )
        self.title = vessel.name
        self.subtitle = [
            vessel.speed.map { "\($0) knots" },
            vessel.lastReceived.relativeTimeSinceNowText()
        ].compactMap { $0 }.joined(separator: " • ")
        self.course = vessel.course
    }
}
