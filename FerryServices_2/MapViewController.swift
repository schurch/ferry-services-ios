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

    @IBOutlet var mapView: MKMapView!
    
    var annotations: [MKPointAnnotation]!
    
    override func viewDidLoad() {
        mapView.delegate = self
        mapView.addAnnotations(annotations)
    }

    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        mapView.showAnnotations(self.annotations, animated: false)
    }
}
