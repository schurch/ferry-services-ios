//
//  SearchResultsViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

protocol SearchResultsViewControllerDelegate: class {
    func didSelectServiceStatus(_ serviceStatus: ServiceStatus)
}

class SearchResultsViewController: UIViewController {
    
    static let serviceStatusReuseId = "serviceStatusCellReuseId"
    static let portAnnotationReuseId = "portAnnotationReuseId"

    enum Mode: Int {
        case list = 0
        case map = 1
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfServices: [ServiceStatus] = []
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    fileprivate var arrayOfAnnotations: [MKPointAnnotation] = []
    fileprivate var arrayOfFilteredServices: [ServiceStatus] = []
    fileprivate var arrayOfLocations = Location.fetchLocations()
    fileprivate var bottomInset: CGFloat = 0.0
    fileprivate var previewingIndexPath: IndexPath?
    fileprivate var text: String?
    fileprivate var viewMode: Mode = .list
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: SearchResultsViewController.serviceStatusReuseId)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardShownNotification(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardWillBeHiddenNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.configureView()
        
        registerForPreviewing(with: self, sourceView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.viewMode == .list {
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
    
    fileprivate func configureView() {
        guard self.isViewLoaded else {
            return
        }
        
        switch self.viewMode {
        case .list:
            self.configureListView()
        case .map:
            self.configureMapView()
        }
    }
    
    fileprivate func configureListView() {
        self.filterResults()
        
        self.tableView.reloadData()
        
        self.tableView.isHidden = false
        self.mapView.isHidden = true
    }
    
    fileprivate func configureMapView() {
        self.filterResults()
        
        self.tableView.isHidden = true
        self.mapView.isHidden = false
    }
    
    // MARK: - Public
    func keyboardShownNotification(_ notification: Notification) {
        if let height = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height {
            let inset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: height, right: 0.0)
            self.tableView.contentInset = inset
            self.tableView.scrollIndicatorInsets = inset
            
            self.bottomInset = height + 10.0
            
            self.showVisibleMapRectAnimated(false)
        }
    }
    
    func keyboardWillBeHiddenNotification(_ notification: Notification) {
        self.tableView.contentInset = UIEdgeInsets.zero
        self.tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        self.bottomInset = 0.0
        
        self.showVisibleMapRectAnimated(false)
    }
    
    func showList() {
        self.viewMode = .list
        self.configureView()
    }
    
    func showMap() {
        self.viewMode = .map
        self.configureView()
    }
    
    // MARK: - Utility methods
    fileprivate func filterResults() {
        guard let filterText = self.text else {
            return
        }
        
        switch self.viewMode {
        case .list:
            self.arrayOfFilteredServices = self.arrayOfServices.filter { service in
                var containsArea = false
                if let area = service.area?.lowercased() {
                    containsArea = area.contains(filterText.lowercased())
                }
                
                var containsRoute = false
                if let route = service.route?.lowercased() {
                    containsRoute = route.contains(filterText.lowercased())
                }
                
                return containsArea || containsRoute
            }
            
            self.tableView.reloadData()
        case .map:
            if let locations = self.arrayOfLocations {
                let filteredLocations = locations.filter { location in
                    if let containsString = location.name?.lowercased().contains(filterText.lowercased()) {
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
    
    fileprivate func annotationsForLocations(_ locations: [Location]) -> [MKPointAnnotation] {
        return locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.title = location.name
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
            return annotation
        }
    }
    
    fileprivate func showVisibleMapRectAnimated(_ animated: Bool) {
        if let locations = self.arrayOfLocations {
            let allAnnotations = self.annotationsForLocations(locations)
            let rect = calculateMapRectForAnnotations(allAnnotations)
            let visibleRect = self.mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets(top: 50.0, left: 25.0, bottom: self.bottomInset, right: 40.0))
            self.mapView.setVisibleMapRect(visibleRect, animated: animated)
        }
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.text = searchController.searchBar.text
        self.filterResults()
    }
}

extension SearchResultsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayOfFilteredServices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serviceStatusCell = self.tableView.dequeueReusableCell(withIdentifier: SearchResultsViewController.serviceStatusReuseId, for: indexPath) as! ServiceStatusCell
        let serviceStatus = self.arrayOfFilteredServices[(indexPath as NSIndexPath).row]
        serviceStatusCell.configureCellWithServiceStatus(serviceStatus)
        
        return serviceStatusCell
    }
}

extension SearchResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectServiceStatus(self.arrayOfFilteredServices[(indexPath as NSIndexPath).row])
    }
}

extension SearchResultsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: SearchResultsViewController.portAnnotationReuseId) as! MKPinAnnotationView!
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: SearchResultsViewController.portAnnotationReuseId)
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation
        
        let placemark = MKPlacemark(coordinate: annotation!.coordinate, addressDictionary: nil)
        
        let destination = MKMapItem(placemark: placemark)
        destination.name = annotation!.title!
        
        let items = [destination]
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        MKMapItem.openMaps(with: items, launchOptions: options)
    }
}

extension SearchResultsViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }

        previewingContext.sourceRect = cell.frame
        
        previewingIndexPath = indexPath
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .previewing
        
        let serviceStatus = self.arrayOfFilteredServices[(indexPath as NSIndexPath).row]
        serviceDetailViewController.serviceStatus = serviceStatus
        
        return serviceDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let previewingIndexPath = previewingIndexPath else { return }
        
        self.delegate?.didSelectServiceStatus(self.arrayOfFilteredServices[(previewingIndexPath as NSIndexPath).row])
    }
}
