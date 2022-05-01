//
//  MapViewHelpers.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/05/22.
//  Copyright © 2022 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

class MapViewHelpers {
    static func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case let vesselAnnotation as VesselAnnotation:
            let ferryView = mapView.dequeueReusableAnnotationView(withIdentifier: "ferry") ?? MKAnnotationView(annotation: vesselAnnotation, reuseIdentifier: "ferry")
            ferryView.annotation = vesselAnnotation
            ferryView.displayPriority = .required
            ferryView.canShowCallout = true
            ferryView.image = UIImage(named: "ferry")!.rotated(by: vesselAnnotation.course ?? 0)
            
            return ferryView
            
        case let locationAnnotation as LocationAnnotation:
            let locationView = mapView.dequeueReusableAnnotationView(withIdentifier: "location") ?? MKMarkerAnnotationView(annotation: locationAnnotation, reuseIdentifier: "location")
            locationView.annotation = locationAnnotation
            locationView.displayPriority = .required
            locationView.canShowCallout = true
            
            let directionsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 100))
            directionsButton.backgroundColor = UIColor(red:0.13, green:0.75, blue:0.67, alpha:1)
            directionsButton.setImage(UIImage(named: "directions_arrow"), for: UIControl.State())
            directionsButton.setImage(UIImage(named: "directions_arrow_highlighted"), for: UIControl.State.highlighted)
            directionsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 56, right: 0)
            locationView.rightCalloutAccessoryView = directionsButton
            
            return locationView
            
        default :
            return nil
        }
    }
    
    static func calculateMapRect(forLocations locations: [Service.Location]) -> MKMapRect {
        return locations.reduce(MKMapRect.null) { rect, location in
            rect.union(
                MKMapRect(
                    origin: MKMapPoint.init(
                        CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                    ),
                    size: MKMapSize(width: 0.1, height: 0.1)
                )
            )
        }
    }
}
