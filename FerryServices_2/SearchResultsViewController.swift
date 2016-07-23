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
    private var bottomInset: CGFloat = 0.0
    private var previewingIndexPath: NSIndexPath?
    private var text: String?
    private var viewMode: Mode = .List
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: SearchResultsViewController.serviceStatusReuseId)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchResultsViewController.keyboardShownNotification(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SearchResultsViewController.keyboardWillBeHiddenNotification(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        self.configureView()
        
        registerForPreviewingWithDelegate(self, sourceView: tableView)
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
            self.configureListView()
        case .Map:
            self.configureMapView()
        }
    }
    
    private func configureListView() {
        self.filterResults()
        
        self.tableView.reloadData()
        
        self.tableView.hidden = false
        self.mapView.hidden = true
    }
    
    private func configureMapView() {
        self.filterResults()
        
        self.tableView.hidden = true
        self.mapView.hidden = false
    }
    
    // MARK: - Public
    func keyboardShownNotification(notification: NSNotification) {
        if let height = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size.height {
            let inset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: height, right: 0.0)
            self.tableView.contentInset = inset
            self.tableView.scrollIndicatorInsets = inset
            
            self.bottomInset = height + 10.0
            
            self.showVisibleMapRectAnimated(false)
        }
    }
    
    func keyboardWillBeHiddenNotification(notification: NSNotification) {
        self.tableView.contentInset = UIEdgeInsetsZero
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero
        
        self.bottomInset = 0.0
        
        self.showVisibleMapRectAnimated(false)
    }
    
    func showList() {
        self.viewMode = .List
        self.configureView()
    }
    
    func showMap() {
        self.viewMode = .Map
        self.configureView()
    }
    
    // MARK: - Utility methods
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
                
                let annotations = annotationsForLocations(filteredLocations)
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(annotations)
                
                self.showVisibleMapRectAnimated(true)
            }
        }
    }
    
    private func annotationsForLocations(locations: [Location]) -> [MKPointAnnotation] {
        return locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.title = location.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            return annotation
        }
    }
    
    private func showVisibleMapRectAnimated(animated: Bool) {
        if let locations = self.arrayOfLocations {
            let allAnnotations = self.annotationsForLocations(locations)
            let rect = calculateMapRectForAnnotations(allAnnotations)
            let visibleRect = self.mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets(top: 50.0, left: 25.0, bottom: self.bottomInset, right: 40.0))
            self.mapView.setVisibleMapRect(visibleRect, animated: animated)
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

extension SearchResultsViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }

        previewingContext.sourceRect = cell.frame
        
        previewingIndexPath = indexPath
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .Previewing
        
        let serviceStatus = self.arrayOfFilteredServices[indexPath.row]
        serviceDetailViewController.serviceStatus = serviceStatus
        
        return serviceDetailViewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        guard let previewingIndexPath = previewingIndexPath else { return }
        
        self.delegate?.didSelectServiceStatus(self.arrayOfFilteredServices[previewingIndexPath.row])
    }
}
