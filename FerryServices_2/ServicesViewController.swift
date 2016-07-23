//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import Flurry_iOS_SDK

class ServicesViewController: UITableViewController {
    
    // MARK: - Variables & Constants
    static let subscribedServiceIdsUserDefaultsKey = "com.ferryservices.userdefaultkeys.subscribedservices"
    
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCellReuseId"
        }
    }
    
    private struct Constants {
        struct TableViewSections {
            static let subscribed = 0
            static let services = 1
        }
        struct TableViewSectionHeaders {
            static let subscribed = "Subscribed"
            static let services = "Services"
        }
        struct PullToRefresh {
            static let refreshOffset = CGFloat(120.0)
        }
    }
    
    private var arrayServiceStatuses = [ServiceStatus]()
    private var arraySubscribedServiceStatuses = [ServiceStatus]()
    private var previewingIndexPath: NSIndexPath?
    private var propellerView: PropellerView!
    private var refreshing = false
    private var searchController: UISearchController!
    private var searchResultsController: SearchResultsViewController!
    
    // Set if we should show a service when finished loading
    private var serviceIdToShow: Int?
    
    // MARK: -
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Public
    func showDetailsForServiceId(serviceId: Int, shouldFindAndHighlightRow: Bool = false) {
        if self.arrayServiceStatuses.count == 0 {
            // We haven't loaded yet so set the service ID to show when we do
            self.serviceIdToShow = serviceId
        }
        else {
            self.navigationController?.popToRootViewControllerAnimated(false)
            
            if let index = self.indexOfServiceWithServiceId(serviceId, services: self.arrayServiceStatuses) {
                if shouldFindAndHighlightRow {
                    let section = !self.arraySubscribedServiceStatuses.isEmpty ? 1 : 0
                    let indexPath = NSIndexPath(forRow: index, inSection: section)
                    self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Middle)
                }
                
                let serviceStatus = self.arrayServiceStatuses[index]
                
                let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ServiceDetailTableViewController") as! ServiceDetailTableViewController
                serviceDetailViewController.serviceStatus = serviceStatus
                
                if let route = serviceStatus.route {
                    Flurry.logEvent("Viewed service detail", withParameters: ["Route": route])
                }
                else {
                    Flurry.logEvent("Viewed service detail")
                }
                
                self.navigationController?.pushViewController(serviceDetailViewController, animated: true)
            }
        }
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ServicesViewController.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.tealBackgroundColor()
        self.tableView.registerNib(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: MainStoryboard.TableViewCellIdentifiers.serviceStatusCell)
        
        self.searchResultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SearchResultsController") as! SearchResultsViewController
        self.searchResultsController.delegate = self
            
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        self.searchController.searchResultsUpdater = self.searchResultsController
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.barTintColor = UIColor.tealBackgroundColor()
        self.searchController.searchBar.scopeButtonTitles = ["Services", "Ferry Terminals"]
        self.searchController.delegate = self
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        self.definesPresentationContext = true
        
        searchController.searchBar.layer.borderColor = UIColor.tealBackgroundColor().CGColor
        searchController.searchBar.layer.borderWidth = 1
        
        // Grey subview in tableview appears when pulling to refresh. Not sure what it's for :/
        for subview in self.tableView.subviews {
            if subview.frame.origin.y < 0 {
                subview.alpha = 0.0
            }
        }
        
        self.loadDefaultFerryServices()
        
        // custom pull to refresh
        propellerView = PropellerView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        propellerView.center = CGPoint(x: self.tableView.bounds.size.width/2, y: -24)
        propellerView.percentComplete = 0.0
        self.tableView.addSubview(propellerView)
        
        self.tableView.rowHeight = 44
        
        if let serviceIdToShow = self.serviceIdToShow {
            // If this is set, then there was a request to show a service before the view had loaded
            self.showDetailsForServiceId(serviceIdToShow, shouldFindAndHighlightRow: true)
            self.serviceIdToShow = nil
        }
        
        self.searchResultsController.arrayOfServices = self.arrayServiceStatuses
        
        self.refreshWithContentInsetReset(false)
        
        registerForPreviewingWithDelegate(self, sourceView: view)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        self.arraySubscribedServiceStatuses = self.generateArrayOfSubscribedServiceIds()
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Using a hack to stop search bar disappearing when it becomes active by setting this to true,
        // so set it to false when the view disappears
        self.navigationController?.navigationBar.translucent = false
    }
    
    // MARK: - Notifications
    func applicationDidBecomeActive(notification: NSNotification) {
        self.refreshWithContentInsetReset(false)
    }
    
    // MARK: - Refresh
    func refreshWithContentInsetReset(resetContentInset: Bool) {
        self.refreshing = true
        self.propellerView.percentComplete = 1.0
        self.propellerView.startRotating()
        
        ServicesAPIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
            if let statuses = serviceStatuses {
                self.arrayServiceStatuses = statuses
                self.arraySubscribedServiceStatuses = self.generateArrayOfSubscribedServiceIds()
                self.searchResultsController.arrayOfServices = self.arrayServiceStatuses
            }
            
            self.tableView.reloadData()
            
            // reset pull to refresh on completion
            if resetContentInset {
                UIView.animateWithDuration(0.25, animations: {
                    self.tableView.contentInset = UIEdgeInsetsZero
                    }, completion: { (finished) -> () in
                        self.propellerView.stopRotating()
                        self.refreshing = false
                })
            }
            else {
                self.propellerView.stopRotating()
                self.refreshing = false
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.arraySubscribedServiceStatuses.isEmpty ? 1 : 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.arraySubscribedServiceStatuses.isEmpty {
            return nil
        }
        
        switch(section) {
        case Constants.TableViewSections.subscribed:
            return Constants.TableViewSectionHeaders.subscribed
        default:
            return Constants.TableViewSectionHeaders.services
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.arraySubscribedServiceStatuses.isEmpty {
            return self.arrayServiceStatuses.count
        }
        
        switch (section) {
        case Constants.TableViewSections.subscribed:
            return self.arraySubscribedServiceStatuses.count
        default:
            return self.arrayServiceStatuses.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let serviceStatusCell = self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, forIndexPath: indexPath) as! ServiceStatusCell
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: indexPath)
        serviceStatusCell.configureCellWithServiceStatus(serviceStatus)
        
        return serviceStatusCell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let serviceStatus = self.serviceStatusForTableView(tableView, indexPath: indexPath)
        
        if let serviceId = serviceStatus.serviceId {
            self.showDetailsForServiceId(serviceId)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.tealTextColor()
    }
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.refreshing {
            return
        }
        
        let pullToRefreshPercent = min(abs(scrollView.contentOffset.y) / Constants.PullToRefresh.refreshOffset, 1.0)
        propellerView.percentComplete = Float(pullToRefreshPercent)
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < -Constants.PullToRefresh.refreshOffset {
            refreshWithContentInsetReset(true)
            
            let contentOffset = scrollView.contentOffset
            var newInset = scrollView.contentInset
            newInset.top = propellerView.bounds.size.height + 14
            
            UIView.animateWithDuration(0.25) {
                scrollView.contentInset = newInset
                scrollView.contentOffset = contentOffset
            }
        }
    }
    
    // MARK: - Helpers
    private func indexOfServiceWithServiceId(serviceId :Int, services :[ServiceStatus]) -> Int? {
        let filteredServices = services.filter { $0.serviceId == serviceId }
        if let service = filteredServices.first {
            return services.indexOf(service)
        }
        
        return nil
    }

    private func loadDefaultFerryServices() {
        if let defaultServicesFilePath = NSBundle.mainBundle().pathForResource("services", ofType: "json") {
            var fileReadError: NSError?
            do {
                let serviceData = try NSData(contentsOfFile: defaultServicesFilePath, options: .DataReadingMappedIfSafe)
                if fileReadError != nil {
                    NSLog("Error loading default services data: %@", fileReadError!)
                    return
                }
                
                var jsonParseError: NSError?
                
                let serviceStatusData: AnyObject?
                do {
                    serviceStatusData = try NSJSONSerialization.JSONObjectWithData(serviceData, options: [])
                } catch let error as NSError {
                    jsonParseError = error
                    serviceStatusData = nil
                }
                if jsonParseError != nil {
                    NSLog("Error parsing service data json: %@", jsonParseError!)
                    return
                }
                
                let json = JSON(serviceStatusData!)
                
                if let serviceStatuses = json.array?.map({ json in ServiceStatus(data: json) }) {
                    let sortedServiceStatuses = serviceStatuses.sort { $0.sortOrder < $1.sortOrder }
                    self.arrayServiceStatuses = sortedServiceStatuses
                }
            } catch let error as NSError {
                fileReadError = error
            }            
        }
    }
    
    private func serviceStatusForTableView(tableView: UITableView, indexPath: NSIndexPath) -> ServiceStatus {
        if self.arraySubscribedServiceStatuses.isEmpty {
            return self.arrayServiceStatuses[indexPath.row]
        }
        
        switch(indexPath.section) {
        case Constants.TableViewSections.subscribed:
            return self.arraySubscribedServiceStatuses[indexPath.row]
        default:
            return self.arrayServiceStatuses[indexPath.row]
        }
    }
    
    private func generateArrayOfSubscribedServiceIds() -> [ServiceStatus] {
        guard let subscribedServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey(ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] else {
            return [ServiceStatus]()
        }
        
        let subscribedServiceStatuses = subscribedServiceIds.map { serviceId in
            return self.arrayServiceStatuses.filter { $0.serviceId == serviceId }.first
        }
        
        return subscribedServiceStatuses.flatMap({ $0 }).sort({ $0.sortOrder < $1.sortOrder })
    }
}

extension ServicesViewController: SearchResultsViewControllerDelegate {
    func didSelectServiceStatus(serviceStatus: ServiceStatus) {
        if let serviceId = serviceStatus.serviceId {
            self.showDetailsForServiceId(serviceId)
        }
    }
}

extension ServicesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            self.searchResultsController.showList()
        case 1:
            self.searchResultsController.showMap()
        default:
            print("Unknown scope selection")
        }
    }
}

extension ServicesViewController: UISearchControllerDelegate {
    // Hack to stop searchbar disappearing off screen when it becomes active
    
    func willPresentSearchController(searchController: UISearchController) {
        self.navigationController?.navigationBar.translucent = true
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        self.navigationController?.navigationBar.translucent = false
    }
}

extension ServicesViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        previewingIndexPath = indexPath
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .Previewing
        
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: indexPath)
        serviceDetailViewController.serviceStatus = serviceStatus
        
        return serviceDetailViewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        guard let previewingIndexPath = previewingIndexPath else { return }
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .Full
        
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: previewingIndexPath)
        serviceDetailViewController.serviceStatus = serviceStatus
        
        showViewController(serviceDetailViewController, sender: self)

    }
}
