//
//  MapViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    private struct Constants {
        static let portAnnotationReuseIdentifier = "PortAnnotationReuseId"
    }

    @IBOutlet var mapView: MKMapView!
    
    var annotations: [MKPointAnnotation]!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.addAnnotations(annotations)
    }

    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        mapView.showAnnotations(self.annotations, animated: false)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation.self) {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.portAnnotationReuseIdentifier) as! MKPinAnnotationView!
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.portAnnotationReuseIdentifier)
            pinView.pinTintColor = MKPinAnnotationView.redPinColor()
            pinView.animatesDrop = false
            pinView.canShowCallout = true
            
            let directionsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 100))
            directionsButton.backgroundColor = UIColor(red:0.13, green:0.75, blue:0.67, alpha:1)
            directionsButton.setImage(UIImage(named: "directions_arrow"), forState: UIControlState.Normal)
            directionsButton.setImage(UIImage(named: "directions_arrow_highlighted"), forState: UIControlState.Highlighted)
            directionsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 56, right: 0)
            
            pinView.rightCalloutAccessoryView = directionsButton
        }
        else {
            pinView.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        Flurry.logEvent("Show driving directions to port")
        
        let annotation = view.annotation
        
        let placemark = MKPlacemark(coordinate: annotation!.coordinate, addressDictionary: nil)
        
        let destination = MKMapItem(placemark: placemark)
        destination.name = annotation!.title!
        
        let items = [destination]
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        MKMapItem.openMapsWithItems(items, launchOptions: options)
    }
}
