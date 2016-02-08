//
//  VesselMapConfigurator.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/02/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

protocol VesselMapConfigurator {
    func configureMap(map: MKMapView, vessels: [Vessel])
}

extension VesselMapConfigurator {
    func configureMap(map: MKMapView, vessels: [Vessel]) {
        print("Configure map for vessel: \(vessels[0].name)")
    }
}
