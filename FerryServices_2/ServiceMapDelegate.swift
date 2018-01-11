//
//  ServiceMapDelegate.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/09/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import UIKit
import MapKit
import RxSwift

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
    
    private var disposeBag: DisposeBag = DisposeBag()
    private var mapView: MKMapView
    private(set) var portAnnotations: [MKPointAnnotation]
    private var showVessels: Bool
    
    init(mapView: MKMapView, locations: [Location], showVessels: Bool) {
        self.mapView = mapView
        self.showVessels = showVessels
        
        portAnnotations = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.title = location.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            return annotation
        }
        
        mapView.addAnnotations(portAnnotations)
        
        super.init()
        
        if self.showVessels {
            fetchVessels()
            NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    //MARK: Public
    func showPorts() {
        mapView.showAnnotations(portAnnotations, animated: false)
    }
    
    @objc func applicationDidBecomeActive() {
        refresh()
    }
    
    func refresh() {
        if self.showVessels {
            fetchVessels()
        }
    }
    
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        if annotation.isKind(of: VesselAnnotation.self) {
            return createFerryAnnotationView(mapView: mapView, annotation: annotation)
        }
        else {
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
        }
        else {
            ferryView?.annotation = annotation
        }
        
        let ferryImage = UIImage(named: "ferry")!
        if let course = vesselAnnotation.vessel.course {
            ferryView?.image = ferryImage.rotated(by: course)
        }
        else {
            ferryView?.image = ferryImage
        }
        
        return ferryView
    }
    
    private func createPortAnnotationView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.portAnnotationReuseIdentifier) as! MKPinAnnotationView!
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.portAnnotationReuseIdentifier)
            pinView?.pinTintColor = UIColor.red
            pinView?.animatesDrop = false
            pinView?.canShowCallout = true
            
            let directionsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 100))
            directionsButton.backgroundColor = UIColor(red:0.13, green:0.75, blue:0.67, alpha:1)
            directionsButton.setImage(UIImage(named: "directions_arrow"), for: UIControlState())
            directionsButton.setImage(UIImage(named: "directions_arrow_highlighted"), for: UIControlState.highlighted)
            directionsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 56, right: 0)
            
            pinView?.rightCalloutAccessoryView = directionsButton
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    private func fetchVessels() {
        VesselsAPIClient.fetchVessels()
            .map { vessels in
                return vessels.map { vessel -> VesselAnnotation in
                    let annotation = VesselAnnotation(vessel: vessel)
                    annotation.coordinate = CLLocationCoordinate2D(latitude: vessel.latitude, longitude: vessel.longitude)
                    annotation.title = vessel.name
                    annotation.subtitle = vessel.statusDescription
                    
                    return annotation
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { annotations in
                let vesselAnnotations = self.mapView.annotations.filter { $0.isKind(of: VesselAnnotation.self) }
                self.mapView.removeAnnotations(vesselAnnotations)
                self.mapView.addAnnotations(annotations)
            })
            .disposed(by: disposeBag)
    }
}
