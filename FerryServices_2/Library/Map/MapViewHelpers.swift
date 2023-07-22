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
    private class VesselAnnotationView: MKAnnotationView {
        private var observation: NSKeyValueObservation?
        
        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setup() {
            guard let vesselAnnotation = annotation as? VesselAnnotation else { return }
            observation = vesselAnnotation.observe(\.course, options: .new) { [weak self] object, change in
                guard let newCourse = change.newValue else { return }
                self?.image = UIImage(named: "ferry")!.rotated(by: newCourse)
            }
        }
    }
    
    static func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case let vesselAnnotation as VesselAnnotation:
            let ferryView = mapView.dequeueReusableAnnotationView(withIdentifier: "ferry") ?? VesselAnnotationView(annotation: vesselAnnotation, reuseIdentifier: "ferry")
            ferryView.annotation = vesselAnnotation
            ferryView.displayPriority = .required
            ferryView.canShowCallout = true
            ferryView.image = UIImage(named: "ferry")!.rotated(by: vesselAnnotation.course)
            
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
        let rect = locations.reduce(MKMapRect.null) { rect, location in
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
        
        return rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
    }
}
