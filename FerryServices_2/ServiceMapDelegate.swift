//
//  ServiceMapDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceMapDelegate: NSObject, MKMapViewDelegate {
    
    private struct Constants {
        static let portAnnotationReuseIdentifier = "PortAnnotationReuseId"
    }
    
    var shouldAllowAnnotationSelection = true
    
    private var mapView: MKMapView
    private(set) var portAnnotations: [MKPointAnnotation]
    
    init(mapView: MKMapView, locations: [Service.Location]) {
        self.mapView = mapView
        
        portAnnotations = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.title = location.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            return annotation
        }
        
        mapView.addAnnotations(portAnnotations)
        
        super.init()
    }
    
    //MARK: Public
    func showPorts() {
        mapView.showAnnotations(portAnnotations, animated: false)
    }
    
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        return createPortAnnotationView(mapView: mapView, annotation: annotation)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
        
        let placemark = MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil)
        
        let destination = MKMapItem(placemark: placemark)
        if let title = annotation.title {
            destination.name = title
        }
        
        MKMapItem.openMaps(with: [destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if !shouldAllowAnnotationSelection {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
    
    //MARK: - Helpers
    private func createPortAnnotationView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.portAnnotationReuseIdentifier)
        
        guard annotationView == nil else {
            annotationView?.annotation = annotation
            return annotationView
        }
        
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.portAnnotationReuseIdentifier)
        pinAnnotationView.pinTintColor = UIColor.red
        pinAnnotationView.animatesDrop = false
        pinAnnotationView.canShowCallout = true
        
        let directionsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 100))
        directionsButton.backgroundColor = UIColor(red:0.13, green:0.75, blue:0.67, alpha:1)
        directionsButton.setImage(UIImage(named: "directions_arrow"), for: UIControlState())
        directionsButton.setImage(UIImage(named: "directions_arrow_highlighted"), for: UIControlState.highlighted)
        directionsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 56, right: 0)
        
        pinAnnotationView.rightCalloutAccessoryView = directionsButton
        
        return pinAnnotationView
    }
}
