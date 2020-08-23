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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class ServicesViewController: UITableViewController {
    
    // MARK: - Variables & Constants
    static let subscribedServiceIdsUserDefaultsKey = "com.ferryservices.userdefaultkeys.subscribedservices.v2"
    
    fileprivate struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCellReuseId"
        }
    }
    
    fileprivate struct Constants {
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
    
    fileprivate var arrayServiceStatuses = [Service]()
    fileprivate var arraySubscribedServiceStatuses = [Service]()
    fileprivate var previewingIndexPath: IndexPath?
    fileprivate var propellerView: PropellerView!
    fileprivate var refreshing = false
    fileprivate var searchController: UISearchController!
    fileprivate var searchResultsController: SearchResultsViewController!
    
    // Set if we should show a service when finished loading
    fileprivate var serviceIdToShow: Int?
    
    // MARK: -
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    func showDetailsForServiceId(_ serviceId: Int, shouldFindAndHighlightRow: Bool = false) {
        if self.arrayServiceStatuses.count == 0 {
            // We haven't loaded yet so set the service ID to show when we do
            self.serviceIdToShow = serviceId
        }
        else {
            let _ = self.navigationController?.popToRootViewController(animated: false)
            
            if let index = self.indexOfServiceWithServiceId(serviceId, services: self.arrayServiceStatuses) {
                if shouldFindAndHighlightRow {
                    let section = !self.arraySubscribedServiceStatuses.isEmpty ? 1 : 0
                    let indexPath = IndexPath(row: index, section: section)
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
                }
                
                let serviceStatus = self.arrayServiceStatuses[index]
                
                let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
//                serviceDetailViewController.serviceStatus = serviceStatus
                
                self.navigationController?.pushViewController(serviceDetailViewController, animated: true)
            }
        }
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServicesViewController.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.tealBackgroundColor()
        self.tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: MainStoryboard.TableViewCellIdentifiers.serviceStatusCell)
        
        self.searchResultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsController") as! SearchResultsViewController
        self.searchResultsController.delegate = self
            
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        self.searchController.searchResultsUpdater = self.searchResultsController
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.barTintColor = UIColor.tealBackgroundColor()
//        self.searchController.searchBar.scopeButtonTitles = ["Services", "Ferry Terminals"]
        tableView.tableHeaderView = searchController.searchBar
        
        self.definesPresentationContext = true
        
        searchController.searchBar.layer.borderColor = UIColor.tealBackgroundColor().cgColor
        searchController.searchBar.layer.borderWidth = 1
        
        // Grey subview in tableview appears when pulling to refresh. Not sure what it's for :/
        for subview in self.tableView.subviews {
            if subview.frame.origin.y < 0 {
                subview.alpha = 0.0
            }
        }
        
        arrayServiceStatuses = ServiceStatus.defaultServices
        
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
        
        registerForPreviewing(with: self, sourceView: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        self.arraySubscribedServiceStatuses = self.generateArrayOfSubscribedServiceIds()
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Using a hack to stop search bar disappearing when it becomes active by setting this to true,
        // so set it to false when the view disappears
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Notifications
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        self.refreshWithContentInsetReset(false)
    }
    
    // MARK: - Refresh
    func refreshWithContentInsetReset(_ resetContentInset: Bool) {
        self.refreshing = true
        self.propellerView.percentComplete = 1.0
        self.propellerView.startRotating()
        
        API.fetchServices { result in
            guard case let .success(services) = result else { return }

            self.arrayServiceStatuses = services.sorted(by: { $0.sortOrder < $1.sortOrder })
            self.arraySubscribedServiceStatuses = self.generateArrayOfSubscribedServiceIds()
            self.searchResultsController.arrayOfServices = self.arrayServiceStatuses

            self.tableView.reloadData()

            // reset pull to refresh on completion
            if resetContentInset {
                UIView.animate(withDuration: 0.25, animations: {
                    self.tableView.contentInset = UIEdgeInsets.zero
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.arraySubscribedServiceStatuses.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serviceStatusCell = self.tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, for: indexPath) as! ServiceStatusCell
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: indexPath)
        serviceStatusCell.configureCellWithServiceStatus(serviceStatus)
        
        return serviceStatusCell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let serviceStatus = self.serviceStatusForTableView(tableView, indexPath: indexPath)
        self.showDetailsForServiceId(serviceStatus.id)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.tealTextColor()
    }
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.refreshing {
            return
        }
        
        let pullToRefreshPercent = min(abs(scrollView.contentOffset.y) / Constants.PullToRefresh.refreshOffset, 1.0)
        propellerView.percentComplete = Float(pullToRefreshPercent)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < -Constants.PullToRefresh.refreshOffset {
            refreshWithContentInsetReset(true)
            
            let contentOffset = scrollView.contentOffset
            var newInset = scrollView.contentInset
            newInset.top = propellerView.bounds.size.height + 14
            
            UIView.animate(withDuration: 0.25, animations: {
                scrollView.contentInset = newInset
                scrollView.contentOffset = contentOffset
            }) 
        }
    }
    
    // MARK: - Helpers
    fileprivate func indexOfServiceWithServiceId(_ serviceId :Int, services :[Service]) -> Int? {
        let filteredServices = services.filter { $0.id == serviceId }
        return filteredServices.firstIndex(where: { $0.id == serviceId})
    }
    
    fileprivate func serviceStatusForTableView(_ tableView: UITableView, indexPath: IndexPath) -> Service {
        if self.arraySubscribedServiceStatuses.isEmpty {
            return self.arrayServiceStatuses[(indexPath as NSIndexPath).row]
        }
        
        switch((indexPath as NSIndexPath).section) {
        case Constants.TableViewSections.subscribed:
            return self.arraySubscribedServiceStatuses[(indexPath as NSIndexPath).row]
        default:
            return self.arrayServiceStatuses[(indexPath as NSIndexPath).row]
        }
    }
    
    fileprivate func generateArrayOfSubscribedServiceIds() -> [Service] {
        guard let subscribedServiceIds = UserDefaults.standard.array(forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] else {
            return [Service]()
        }
        
        let subscribedServiceStatuses = subscribedServiceIds.map { serviceId in
            return self.arrayServiceStatuses.filter { $0.id == serviceId }.first
        }
        
        return subscribedServiceStatuses.compactMap({ $0 }).sorted(by: { $0.sortOrder < $1.sortOrder })
    }
}

extension ServicesViewController: SearchResultsViewControllerDelegate {
    func didSelectServiceStatus(_ serviceStatus: Service) {
        self.showDetailsForServiceId(serviceStatus.id)
    }
}

extension ServicesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
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

extension ServicesViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        previewingIndexPath = indexPath
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .previewing
        
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: indexPath)
//        serviceDetailViewController.serviceStatus = serviceStatus
        
        return serviceDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let previewingIndexPath = previewingIndexPath else { return }
        
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.viewConfiguration = .full
        
        let serviceStatus = serviceStatusForTableView(tableView, indexPath: previewingIndexPath)
//        serviceDetailViewController.serviceStatus = serviceStatus
        
        show(serviceDetailViewController, sender: self)

    }
}
