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
    @objc dynamic var course: Double
    
    var vessel: Vessel {
        didSet {
            configure()
        }
    }
    
    init(vessel: Vessel) {
        self.vessel = vessel
        self.coordinate = CLLocationCoordinate2D(
            latitude: vessel.latitude,
            longitude: vessel.longitude
        )
        self.course = 0
        
        super.init()
        
        configure()
    }
    
    private func configure() {
        coordinate = CLLocationCoordinate2D(
            latitude: vessel.latitude,
            longitude: vessel.longitude
        )
        title = vessel.name
        subtitle = [
            vessel.speed.map { String(format: NSLocalizedString("%.1f knots", comment: ""), $0) },
            vessel.lastReceived.formatted(.relative(presentation: .numeric))
        ].compactMap { $0 }.joined(separator: " • ")
        
        course = vessel.course ?? 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? VesselAnnotation else { return false }
        return vessel.mmsi == object.vessel.mmsi
        
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(vessel.mmsi)
        return hasher.finalize()
    }
}
