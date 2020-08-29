//
//  MapViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    
    var locations: [Service.Location]?
    
    private var mapViewDelegate: ServiceMapDelegate!
    private var didShowAnnotations = false
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let locations = self.locations {
            mapViewDelegate = ServiceMapDelegate(mapView: mapView, locations: locations, showVessels: true)
            mapView.delegate = mapViewDelegate            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didShowAnnotations {
            mapViewDelegate.showPorts()
            didShowAnnotations = true
        }
    }
    
}
