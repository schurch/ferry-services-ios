//
//  SearchResultsViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit
import MapKit
import Flurry_iOS_SDK

protocol SearchResultsViewControllerDelegate: class {
    func didSelectServiceStatus(serviceStatus: ServiceStatus)
}

class SearchResultsViewController: UIViewController {
    
    static let serviceStatusReuseId = "serviceStatusCellReuseId"
    static let portAnnotationReuseId = "portAnnotationReuseId"

    enum Mode: Int {
        case List = 0
        case Map = 1
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfServices: [ServiceStatus] = []
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    private var arrayOfAnnotations: [MKPointAnnotation] = []
    private var arrayOfFilteredServices: [ServiceStatus] = []
    private var arrayOfLocations = Location.fetchLocations()
    private var text: String?
    private var viewMode: Mode = .List
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: SearchResultsViewController.serviceStatusReuseId)
        
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.viewMode == .List {
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
            }
        }
    }
    
    private func configureView() {
        guard self.isViewLoaded() else {
            return
        }
        
        switch self.viewMode {
        case .List:
            configureListView()
        case .Map:
            configureMapView()
        }
    }
    
    private func configureListView() {
        filterResults()
        
        self.tableView.reloadData()
        
        self.tableView.hidden = false
        self.mapView.hidden = true
    }
    
    private func configureMapView() {
        filterResults()
        
        // Show scotland
        let coordinate = CLLocationCoordinate2D(latitude: 56.1, longitude: -4.5)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 500000, 500000)
        self.mapView.setRegion(self.mapView.regionThatFits(region), animated: false)
        
        self.tableView.hidden = true
        self.mapView.hidden = false
    }
    
    // MARK: - Public
    func showList() {
        self.viewMode = .List
        self.configureView()
    }
    
    func showMap() {
        self.viewMode = .Map
        self.configureView()
    }
    
    private func filterResults() {
        guard let filterText = self.text else {
            return
        }
        
        switch self.viewMode {
        case .List:
            self.arrayOfFilteredServices = self.arrayOfServices.filter { service in
                var containsArea = false
                if let area = service.area?.lowercaseString {
                    containsArea = area.containsString(filterText.lowercaseString)
                }
                
                var containsRoute = false
                if let route = service.route?.lowercaseString {
                    containsRoute = route.containsString(filterText.lowercaseString)
                }
                
                return containsArea || containsRoute
            }
            
            self.tableView.reloadData()
        case .Map:
            if let locations = self.arrayOfLocations {
                let filteredLocations = locations.filter { location in
                    if let containsString = location.name?.lowercaseString.containsString(filterText.lowercaseString) {
                        return containsString
                    }
                    
                    return false
                }
                
                let annotations: [MKPointAnnotation] = filteredLocations.map { location in
                    let annotation = MKPointAnnotation()
                    annotation.title = location.name
                    annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
                    return annotation
                }
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(annotations)
            }
        }
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.text = searchController.searchBar.text
        self.filterResults()
    }
}

extension SearchResultsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayOfFilteredServices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let serviceStatusCell = self.tableView.dequeueReusableCellWithIdentifier(SearchResultsViewController.serviceStatusReuseId, forIndexPath: indexPath) as! ServiceStatusCell
        let serviceStatus = self.arrayOfFilteredServices[indexPath.row]
        serviceStatusCell.configureCellWithServiceStatus(serviceStatus)
        
        return serviceStatusCell
    }
}

extension SearchResultsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.didSelectServiceStatus(self.arrayOfFilteredServices[indexPath.row])
    }
}

extension SearchResultsViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation.self) {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(SearchResultsViewController.portAnnotationReuseId) as! MKPinAnnotationView!
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: SearchResultsViewController.portAnnotationReuseId)
            pinView.pinTintColor = UIColor.redColor()
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
