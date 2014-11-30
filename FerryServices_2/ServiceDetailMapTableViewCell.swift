//
//  ServiceDetailMapTableViewCell.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailMapTableViewCell: UITableViewCell {
    
    @IBOutlet var mapView :MKMapView!
    
    var annotations: [MKPointAnnotation]?
    
    // MARK: - configure cell
    func configureCellForLocations(locations: [Location]) {
        if let annotations = self.annotations {
            self.mapView.removeAnnotations(annotations)
        }
        
        let annotations: [MKPointAnnotation]? = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.title = location.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            return annotation
        }
        
        self.annotations = annotations
        
        if self.annotations != nil {
            self.mapView.addAnnotations(self.annotations!)
            setVisibleRect()
        }
    }
    
    func setVisibleRect() {
        if let annotations = self.annotations {
            let mapRect = calculateMapRectForAnnotations(annotations)
            self.mapView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 40, left: 20, bottom: 5, right: 20), animated: true)
        }
    }
    
    // MARK: -
    private func calculateMapRectForAnnotations(annotations: [MKPointAnnotation]) -> MKMapRect {
        var mapRect = MKMapRectNull
        for annotation in annotations {
            let point = MKMapPointForCoordinate(annotation.coordinate)
            mapRect = MKMapRectUnion(mapRect, MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
        }
        return mapRect
    }
}
