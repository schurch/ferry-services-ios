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
    
    var service: Service!
    
    private var didShowLocations = false
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navigationItem.scrollEdgeAppearance = navBarAppearance
                
        mapView.delegate = self
        mapView.addAnnotations(service.locations.map(LocationAnnotation.init))
        mapView.addAnnotations((service.vessels ?? []).map(VesselAnnotation.init))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didShowLocations {
            mapView.showAnnotations(
                mapView.annotations.filter({ $0 is LocationAnnotation }),
                animated: false
            )
            didShowLocations = true
        }
    }
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MapViewHelpers.mapView(mapView, viewFor: annotation)
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
}
