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
    
    private class VesselAnnotation: MKPointAnnotation {
        var vessel: Vessel
        
        init(vessel: Vessel) {
            self.vessel = vessel
        }
    }
    private struct Constants {
        static let portAnnotationReuseIdentifier = "PortAnnotationReuseId"
        static let ferryAnnotationReuseId = "FerryAnnotationReuseId"
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
     
        fetchVessels()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //MARK: Public
    func showPorts() {
        mapView.showAnnotations(portAnnotations, animated: false)
    }
    
    @objc func applicationDidBecomeActive() {
        refresh()
    }
    
    func refresh() {
            fetchVessels()
    }
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        if annotation.isKind(of: VesselAnnotation.self) {
            return createFerryAnnotationView(mapView: mapView, annotation: annotation)
        } else {
            return createPortAnnotationView(mapView: mapView, annotation: annotation)
        }
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
    private func createFerryAnnotationView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView? {
        guard let vesselAnnotation = annotation as? VesselAnnotation else { return nil }
        
        var ferryView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.ferryAnnotationReuseId)
        
        if ferryView == nil {
            ferryView = MKAnnotationView(annotation: vesselAnnotation, reuseIdentifier: Constants.ferryAnnotationReuseId)
            ferryView?.canShowCallout = true
        } else {
            ferryView?.annotation = annotation
        }
        
        ferryView?.image = UIImage(named: "ferry")!.rotated(by: vesselAnnotation.vessel.course ?? 0)
        
        return ferryView
    }
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
        directionsButton.setImage(UIImage(named: "directions_arrow"), for: UIControl.State())
        directionsButton.setImage(UIImage(named: "directions_arrow_highlighted"), for: UIControl.State.highlighted)
        directionsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 56, right: 0)
        
        pinAnnotationView.rightCalloutAccessoryView = directionsButton
        
        return pinAnnotationView
    }
    
    private func fetchVessels() {
        APIClient.fetchVessels { result in
            guard case let .success(vessels) = result else { return }
            
            let newAnnotations: [VesselAnnotation] = vessels.map { vessel in
                let annotation = VesselAnnotation(vessel: vessel)
                annotation.coordinate = CLLocationCoordinate2D(latitude: vessel.latitude, longitude: vessel.longitude)
                annotation.title = vessel.name
                annotation.subtitle = [
                    vessel.speed.map { "\($0) knots" },
                    vessel.lastReceived.relativeTimeSinceNowText()
                ].compactMap { $0 }.joined(separator: " • ")
                
                return annotation
            }
            
            let currentAnnotations = self.mapView.annotations.filter { $0.isKind(of: VesselAnnotation.self) }
            self.mapView.removeAnnotations(currentAnnotations)
            self.mapView.addAnnotations(newAnnotations)
        }
    }
}
