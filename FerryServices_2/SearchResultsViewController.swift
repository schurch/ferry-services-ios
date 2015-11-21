//
//  SearchResultsViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

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
    
    private var arrayOfFilteredServices: [ServiceStatus] = []
    private var arrayOfAnnotations: [MKPointAnnotation] = []
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
            self.tableView.reloadData()
            
            self.tableView.hidden = false
            self.mapView.hidden = true
        case .Map:
            
            self.tableView.hidden = true
            self.mapView.hidden = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
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
    
    private func filterResultsWithText(filterText: String?) {
        guard let filterText = filterText else {
            return
        }
        
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
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterResultsWithText(searchController.searchBar.text)
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
        
    }
}

extension SearchResultsViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKindOfClass(MKUserLocation.self) else {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(SearchResultsViewController.portAnnotationReuseId) as! MKPinAnnotationView!
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: SearchResultsViewController.portAnnotationReuseId)
            pinView.pinTintColor = UIColor.redColor()
            pinView.animatesDrop = false
            pinView.canShowCallout = true
        }
        else {
            pinView.annotation = annotation
        }
        
        return pinView
    }
}
