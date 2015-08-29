//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Foundation
import FerryServicesCommonTouch

class ServicesViewController: UITableViewController, UISearchDisplayDelegate {
    
    // MARK: - Variables & Constants
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCell"
        }
    }
    
    struct Constants {
        struct TableViewSections {
            static let recent = 0
            static let services = 1
        }
        struct TableViewSectionHeaders {
            static let recent = "Recent"
            static let services = "Services"
        }
        struct TapCount {
            static let userDefaultsKey = "com.ferryservices.userdefaultkeys.tapcount"
            static let minimumCount = 2
        }
        struct PullToRefresh {
            static let refreshOffset = CGFloat(120.0)
        }
    }
    
    private var arrayServiceStatuses = [ServiceStatus]()
    private var arrayFilteredServiceStatuses = [ServiceStatus]()
    private var arrayRecentServiceStatues = [ServiceStatus]()
    
    private var propellerView: PropellerView!
    
    private var refreshing = false
    
    // Set if we should show a service when finished loading
    private var serviceIdToShow: Int?;
    
    private var tapCountDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey("com.ferryservices.userdefaultkeys.tapcount")
        ?? [NSObject: AnyObject]()
    
    // MARK: -
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.tealBackgroundColor()
        
        for subview in self.tableView.subviews {
            if subview.frame.origin.y < 0 {
                subview.alpha = 0.0
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        
        self.loadDefaultFerryServices()
        self.reloadRecents()
        
        self.navigationItem.rightBarButtonItem = self.arrayRecentServiceStatues.count > 0 ? self.editButtonItem() : nil
        
        // custom pull to refresh
        propellerView = PropellerView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        propellerView.center = CGPoint(x: self.tableView.bounds.size.width/2, y: -24)
        propellerView.percentComplete = 0.0
        self.tableView.addSubview(propellerView)
        
        self.tableView.rowHeight = 44;
        
        if let serviceIdToShow = self.serviceIdToShow {
            // If this is set, then there was a request to show a service before the view had loaded
            self.showDetailsForServiceId(serviceIdToShow)
            self.serviceIdToShow = nil
        }
        
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        reloadRecents()
        tableView.reloadData()
        
        navigationItem.rightBarButtonItem = arrayRecentServiceStatues.count > 0 ? editButtonItem() : nil
    }
    
    // MARK: - Handoff
    override func restoreUserActivityState(activity: NSUserActivity) {
        if let userInfo = activity.userInfo {
            if let serviceId = userInfo[UserActivityUserInfoKeys.serviceId] as? Int {
                self.showDetailsForServiceId(serviceId)
            }
        }
    }
    
    // MARK: - Notifications
    func applicationDidBecomeActive(notification: NSNotification) {
        self.refresh()
    }
    
    // MARK: - Refresh
    func refresh() {
        self.refreshing = true
        self.propellerView.percentComplete = 1.0
        self.propellerView.startRotating()
        
        ServicesAPIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
            if let statuses = serviceStatuses {
                self.arrayServiceStatuses = statuses
            }
            
            self.reloadRecents()
            self.navigationItem.rightBarButtonItem = self.arrayRecentServiceStatues.count > 0 ? self.editButtonItem() : nil
            self.tableView.reloadData()
            
            // reset pull to refresh on completion
            UIView.animateWithDuration(0.25, animations: {
                self.tableView.contentInset = UIEdgeInsetsZero
                }, completion: { (finished) -> () in
                    self.propellerView.stopRotating()
                    self.refreshing = false
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.isSearchViewControllerTableView(tableView){
            // We are "searching" so we only have one section
            return 1
        }
        
        return self.arrayRecentServiceStatues.isEmpty ? 1 : 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.isSearchViewControllerTableView(tableView) {
            return nil
        }
        
        if self.arrayRecentServiceStatues.isEmpty {
            return nil
        }
        
        switch(section) {
        case Constants.TableViewSections.recent:
            return Constants.TableViewSectionHeaders.recent
        default:
            return Constants.TableViewSectionHeaders.services
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.isSearchViewControllerTableView(tableView)) {
            return self.arrayFilteredServiceStatuses.count
        }
        
        if self.arrayRecentServiceStatues.isEmpty {
            return self.arrayServiceStatuses.count
        }
        
        switch (section) {
        case Constants.TableViewSections.recent:
            return self.arrayRecentServiceStatues.count
        default:
            return self.arrayServiceStatuses.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let isFiltering = isSearchViewControllerTableView(tableView)
        
        // Dequeue cell
        let serviceStatusCell = isFiltering
            ? self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell) as! ServiceStatusTableViewCell
            : self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, forIndexPath: indexPath) as! ServiceStatusTableViewCell
        
        // Modal object
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: indexPath)
        
        // Configure cell with modal object
        serviceStatusCell.labelTitle.text = serviceStatus.area
        serviceStatusCell.labelSubtitle.text = serviceStatus.route
        
        if let disruptionStatus = serviceStatus.disruptionStatus {
            switch disruptionStatus {
            case .Normal:
                serviceStatusCell.imageViewStatus.image = UIImage(named: "green")
            case .SailingsAffected:
                serviceStatusCell.imageViewStatus.image = UIImage(named: "amber")
            case .SailingsCancelled:
                serviceStatusCell.imageViewStatus.image = UIImage(named: "red")
            case .Unknown:
                serviceStatusCell.imageViewStatus.image = nil
            }
        }
        else {
            serviceStatusCell.imageViewStatus.image = nil
        }
        
        if serviceStatusCell.imageViewStatus.image == nil {
            serviceStatusCell.constraintTitleLeadingSpace.constant = serviceStatusCell.layoutMargins.left
        }
        else {
            serviceStatusCell.constraintTitleLeadingSpace.constant = 42
        }
        
        return serviceStatusCell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView.numberOfSections == 1 {
            return false
        }
        else {
            return !isSearchViewControllerTableView(tableView) && indexPath.section == Constants.TableViewSections.recent
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == Constants.TableViewSections.recent && editingStyle == .Delete {
            
            let serviceStatus = arrayRecentServiceStatues[indexPath.row]
            tapCountDictionary.removeValueForKey(String(serviceStatus.serviceId!))
            
            NSUserDefaults.standardUserDefaults().setObject(tapCountDictionary, forKey: Constants.TapCount.userDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            reloadRecents()
            
            tableView.beginUpdates()
            if arrayRecentServiceStatues.count == 0 {
                tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                setEditing(false, animated: false)
            }
            else {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: Constants.TableViewSections.recent)], withRowAnimation: .Automatic)
            }
            tableView.endUpdates()
            
            navigationItem.rightBarButtonItem = arrayRecentServiceStatues.count > 0 ? editButtonItem() : nil
            
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.sendWatchAppContext()
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.numberOfSections > 1 && indexPath.section == Constants.TableViewSections.recent {
            // don't increment for recent section
            return
        }
        
        let serviceStatus = self.arrayServiceStatuses[indexPath.row]
        if let serviceId = serviceStatus.serviceId {
            self.incrementTapCountForServiceId(serviceId)
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.sendWatchAppContext()
            }
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return !isSearchViewControllerTableView(tableView) && indexPath.section == Constants.TableViewSections.recent ? .Delete : .None
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.tealTextColor()
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
            refresh()
            
            let contentOffset = scrollView.contentOffset
            var newInset = scrollView.contentInset
            newInset.top = propellerView.bounds.size.height + 14
            
            UIView.animateWithDuration(0.25) {
                scrollView.contentInset = newInset
                scrollView.contentOffset = contentOffset
            }
        }
    }
    
    // MARK: - Storyboard
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let serviceDetailViewController = segue.destinationViewController as! ServiceDetailTableViewController;
        let selectedTableView = self.searchDisplayController!.active ? self.searchDisplayController!.searchResultsTableView : self.tableView
        let serviceStatus = self.serviceStatusForTableView(selectedTableView, indexPath: selectedTableView.indexPathForSelectedRow!)
        
        Flurry.logEvent("Viewed service detail", withParameters: ["Route": serviceStatus.route!])
        
        serviceDetailViewController.serviceStatus = serviceStatus
    }
    
    // MARK: - UISearchDisplayController
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.arrayFilteredServiceStatuses = self.arrayServiceStatuses.filter { item in
            
            var containsArea = false
            if let area = item.area {
                containsArea = (area.lowercaseString as NSString).containsString(searchString!.lowercaseString)
            }
            
            var containsRoute = false
            if let route = item.route {
                containsRoute = (route.lowercaseString as NSString).containsString(searchString!.lowercaseString)
            }
            
            return containsArea || containsRoute
        }
        
        return true
    }
    
    // MARK: - Helpers
    func showDetailsForServiceId(serviceId: Int) {
        if self.arrayServiceStatuses.count == 0 {
            // We haven't loaded yet so set the service ID to show when we do
            self.serviceIdToShow = serviceId
        }
        else {
            self.navigationController?.popToRootViewControllerAnimated(false)
            self.searchDisplayController?.setActive(false, animated: false)
            
            if let index = self.indexOfServiceWithServiceId(serviceId, services: self.arrayServiceStatuses) {
                let section = !self.arrayRecentServiceStatues.isEmpty ? 1 : 0;
                let indexPath = NSIndexPath(forRow: index, inSection: section)
                self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Middle)
                self.performSegueWithIdentifier("showServiceDetail", sender: self)
            }
        }
    }
    
    func indexOfServiceWithServiceId(serviceId :Int, services :[ServiceStatus]) -> Int? {
        let filteredServices = services.filter { $0.serviceId == serviceId }
        if let service = filteredServices.first {
            return services.indexOf(service)
        }
        
        return nil
    }
    
    func loadDefaultFerryServices() {
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
                
                let json = JSONValue(serviceStatusData!)
                
                if let serviceStatuses = json.array?.map({ json in ServiceStatus(data: json) }) {
                    self.arrayServiceStatuses = serviceStatuses
                }
            } catch let error as NSError {
                fileReadError = error
            }            
        }
    }
    
    func isSearchViewControllerTableView(tableView: UITableView) -> Bool {
        return tableView == self.searchDisplayController?.searchResultsTableView
    }
    
    func serviceStatusForTableView(tableView: UITableView, indexPath: NSIndexPath) -> ServiceStatus {
        // If we are searching...
        if self.isSearchViewControllerTableView(tableView) {
            return self.arrayFilteredServiceStatuses[indexPath.row]
        }
        
        // If we have a single section...
        if self.numberOfSectionsInTableView(tableView) == 1 {
            return self.arrayServiceStatuses[indexPath.row]
        }
        
        // If we have two sections...
        switch(indexPath.section) {
        case Constants.TableViewSections.recent:
            return self.arrayRecentServiceStatues[indexPath.row]
        default:
            return self.arrayServiceStatuses[indexPath.row]
        }
    }
    
    func incrementTapCountForServiceId(serviceId: Int) {
        func countTaps() -> Int {
            if let count: AnyObject = self.tapCountDictionary[String(serviceId)] {
                return count as! Int
            } else {
                return 0
            }
        }
        
        self.tapCountDictionary[String(serviceId)] = countTaps() + 1
        
        NSUserDefaults.standardUserDefaults().setObject(self.tapCountDictionary, forKey: Constants.TapCount.userDefaultsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func recentServiceIds() -> [Int] {
        var recentServiceIds = [Int]()
        
        for (serviceId, tapCount) in self.tapCountDictionary {
            let count = tapCount as! Int
            
            if count < Constants.TapCount.minimumCount {
                continue
            }
            
            // How to convert NSObject to Int?
            // This is not good :(
            let id = Int((serviceId as! String))
            
            recentServiceIds.append(id!)
        }
        
        return recentServiceIds
    }
    
    func reloadRecents() {
        let ids = self.recentServiceIds()
        
        self.arrayRecentServiceStatues = self.arrayServiceStatuses.filter { item in
            if let id = item.serviceId {
                return ids.contains(id)
            }
            
            return false
        }
    }
    
}
