//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import Foundation

class ServicesViewController: UITableViewController, UISearchDisplayDelegate {
    
    // MARK: - Variables & Constants
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCell"
        }
    }
    
    private struct Constants {
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
    }
    
    private var arrayServiceStatuses = [ServiceStatus]()
    private var arrayFilteredServiceStatuses = [ServiceStatus]()
    private var arrayRecentServiceStatues = [ServiceStatus]()
    
    private var tapCountDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey("com.ferryservices.userdefaultkeys.tapcount")
        ?? [NSObject: AnyObject]()
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.loadDefaultFerryServices()
        self.reloadRecents()
        
        self.navigationItem.rightBarButtonItem = self.arrayRecentServiceStatues.count > 0 ? self.editButtonItem() : nil
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        tableView.contentOffset = CGPoint(x: 0, y: -60)
        self.refreshControl?.beginRefreshing()
        
        self.refresh(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // save before reload so we can reselect
        let selectedIndexPath = tableView.indexPathForSelectedRow()
        
        reloadRecents()
        tableView.reloadData()
        
        if selectedIndexPath != nil {
            tableView.selectRowAtIndexPath(selectedIndexPath!, animated: false, scrollPosition: .None)
        }
    }
    
    // MARK: - Notifications
    func applicationDidBecomeActive(notification: NSNotification) {
        self.refresh(nil)
    }
    
    // MARK: - Refresh
    func refresh(sender: UIRefreshControl?) {
        APIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
            if let statuses = serviceStatuses {
                self.arrayServiceStatuses = statuses
            }
            
            self.reloadRecents()
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
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
            ? self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell) as ServiceStatusTableViewCell
            : self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, forIndexPath: indexPath) as ServiceStatusTableViewCell
        
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
            default:
                serviceStatusCell.imageViewStatus.image = nil
                NSLog("Unrecognised disruption status!")
            }
        }
        else {
            serviceStatusCell.imageViewStatus.image = nil
        }
        
        return serviceStatusCell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView.numberOfSections() == 1 {
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
                tableView.editing = false
            }
            else {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: Constants.TableViewSections.recent)], withRowAnimation: .Automatic)
            }
            tableView.endUpdates()            
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isSearchViewControllerTableView(tableView) {
            return
        }
        
        if tableView.numberOfSections() > 1 && indexPath.section == Constants.TableViewSections.recent {
            // don't increment for recent section
            return
        }
        
        let serviceStatus = self.arrayServiceStatuses[indexPath.row]
        if let serviceId = serviceStatus.serviceId {
            self.incrementTapCountForServiceId(serviceId)
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return !isSearchViewControllerTableView(tableView) && indexPath.section == Constants.TableViewSections.recent ? .Delete : .None
    }
    
    // MARK: - Storyboard
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let serviceDetailViewController = segue.destinationViewController as ServiceDetailTableViewController;
        let selectedTableView = self.searchDisplayController!.active ? self.searchDisplayController!.searchResultsTableView : self.tableView
        let serviceStatus = self.serviceStatusForTableView(selectedTableView, indexPath: selectedTableView.indexPathForSelectedRow()!)
        serviceDetailViewController.serviceStatus = serviceStatus
    }
    
    // MARK: - UISearchDisplayController
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.arrayFilteredServiceStatuses = self.arrayServiceStatuses.filter { item in
            
            var containsArea = false
            if let area = item.area {
                containsArea = (area.lowercaseString as NSString).containsString(searchString)
            }
            
            var containsRoute = false
            if let route = item.route {
                containsRoute = (route.lowercaseString as NSString).containsString(searchString)
            }
            
            return containsArea || containsRoute
        }
        
        return true
    }
    
    // MARK: - Helpers
    func loadDefaultFerryServices() {
        if let defaultServicesFilePath = NSBundle.mainBundle().pathForResource("services", ofType: "json") {
            var fileReadError: NSError?
            let serviceData = NSData.dataWithContentsOfFile(defaultServicesFilePath, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: &fileReadError)
            
            if fileReadError != nil {
                NSLog("Error loading default services data: %@", fileReadError!)
                return
            }
            
            var jsonParseError: NSError?
            
            let serviceStatusData: AnyObject? = NSJSONSerialization.JSONObjectWithData(serviceData, options: nil, error: &jsonParseError)
            if jsonParseError != nil {
                NSLog("Error parsing service data json: %@", jsonParseError!)
                return
            }
            
            let json = JSONValue(serviceStatusData!)
            
            if let serviceStatuses = json["ServiceStatuses"].array?.map({ json in ServiceStatus(data: json) }) {
                self.arrayServiceStatuses = serviceStatuses
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
                return count as Int
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
            let count = tapCount as Int
            
            if count < Constants.TapCount.minimumCount {
                continue
            }
            
            // How to convert NSObject to Int?
            // This is not good :(
            let id = (serviceId as String).toInt()
            
            recentServiceIds.append(id!)
        }
        
        return recentServiceIds
    }
    
    func reloadRecents() {
        let ids = self.recentServiceIds()
        
        self.arrayRecentServiceStatues = self.arrayServiceStatuses.filter { item in
            if let id = item.serviceId {
                return contains(ids, id)
            }
            
            return false
        }
    }
    
}
