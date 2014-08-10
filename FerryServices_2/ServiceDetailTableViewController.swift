//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailTableViewController: UITableViewController {
    
    @IBOutlet var mapView :MKMapView!
    
    var serviceStatus: ServiceStatus?;
    var disruptionDetails: DisruptionDetails?;
    var routeDetails: RouteDetails?;
    
    // MARK: private vars
    private var locations: [Location]?
    
    // MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus?.area
        
        configureMap()
        fetchLatestData()
    }
    
    // MARK: configure view
    private func configureMap() {
        if let serviceId = self.serviceStatus?.serviceId {
            self.locations = Location.fetchLocationsForSericeId(serviceId)
            
            let annotations: [MKPointAnnotation]? = self.locations?.map { location in
                let annotation = MKPointAnnotation()
                annotation.title = location.name
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
                return annotation
            }
            
            if annotations != nil {
                self.mapView.addAnnotations(annotations)
                let mapRect = calculateMapRectForAnnotations(annotations!)
                self.mapView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 40, left: 20, bottom: 5, right: 20), animated: false)
            }
        }
    }
    
    private func configureDisruptionDetails() {
        
    }
    
    // MARK: refresh
    private func fetchLatestData () {
        if let serviceId = self.serviceStatus?.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                self.disruptionDetails = disruptionDetails
                self.routeDetails = routeDetails
                self.configureDisruptionDetails()
            }
        }
    }
    
    // MARK: utility methods
    private func calculateMapRectForAnnotations(annotations: [MKPointAnnotation]) -> MKMapRect {
        var mapRect = MKMapRectNull
        for annotation in annotations {
            let point = MKMapPointForCoordinate(annotation.coordinate)
            mapRect = MKMapRectUnion(mapRect, MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
        }
        return mapRect
    }
}
