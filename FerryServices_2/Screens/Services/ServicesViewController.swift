//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServicesViewController: UITableViewController {
    
    // MARK: - Variables & Constants
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
    }
    
    private var arrayServices = [Service]()
    private var arraySubscribedServices = [Service]()
    private var searchController: UISearchController!
    private var searchResultsController: SearchResultsViewController!
    
    // Set if we should show a service when finished loading
    private var serviceIdToShow: Int?
    
    // MARK: -
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    func showDetailsForServiceId(_ serviceID: Int, shouldFindAndHighlightRow: Bool = false) {
        if self.arrayServices.count == 0 {
            // We haven't loaded yet so set the service ID to show when we do
            self.serviceIdToShow = serviceID
        }
        else {
            let _ = self.navigationController?.popToRootViewController(animated: false)
            
            if let index = arrayServices.firstIndex(where: { $0.serviceId == serviceID }) {
                if shouldFindAndHighlightRow {
                    let section = !self.arraySubscribedServices.isEmpty ? 1 : 0
                    let indexPath = IndexPath(row: index, section: section)
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
                }
                                
                let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
                serviceDetailViewController.service = self.arrayServices[index]
                
                self.navigationController?.pushViewController(serviceDetailViewController, animated: true)
            }
        }
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Services"
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServicesViewController.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: MainStoryboard.TableViewCellIdentifiers.serviceStatusCell)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        searchResultsController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsController") as! SearchResultsViewController)
        searchResultsController.delegate = self
        
        searchController = UISearchController(searchResultsController: self.searchResultsController)
        searchController.searchResultsUpdater = self.searchResultsController
        searchController.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
        
        arrayServices = Service.defaultServices
        
        self.tableView.rowHeight = 44
        
        if let serviceIdToShow = self.serviceIdToShow {
            // If this is set, then there was a request to show a service before the view had loaded
            self.showDetailsForServiceId(serviceIdToShow, shouldFindAndHighlightRow: true)
            self.serviceIdToShow = nil
        }
        
        self.searchResultsController.arrayOfServices = self.arrayServices
        
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        self.arraySubscribedServices = self.generateArrayOfSubscribedServiceIds()
        self.tableView.reloadData()
    }
    
    // MARK: - Notifications
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        self.refresh()
    }
    
    // MARK: - Refresh
    @objc func refresh() {
        API.fetchServices { result in
            self.refreshControl?.endRefreshing()
            
            guard case let .success(services) = result else {
                return
            }

            self.arrayServices = services.sorted(by: { $0.sortOrder < $1.sortOrder })
            self.arraySubscribedServices = self.generateArrayOfSubscribedServiceIds()
            self.searchResultsController.arrayOfServices = self.arrayServices

            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.arraySubscribedServices.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.arraySubscribedServices.isEmpty {
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
        if self.arraySubscribedServices.isEmpty {
            return self.arrayServices.count
        }
        
        switch (section) {
        case Constants.TableViewSections.subscribed:
            return self.arraySubscribedServices.count
        default:
            return self.arrayServices.count
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
        let service = self.serviceStatusForTableView(tableView, indexPath: indexPath)
        self.showDetailsForServiceId(service.serviceId)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor(named: "Text")
    }
    
    // MARK: - Helpers
    fileprivate func serviceStatusForTableView(_ tableView: UITableView, indexPath: IndexPath) -> Service {
        if self.arraySubscribedServices.isEmpty {
            return self.arrayServices[(indexPath as NSIndexPath).row]
        }
        
        switch((indexPath as NSIndexPath).section) {
        case Constants.TableViewSections.subscribed:
            return self.arraySubscribedServices[(indexPath as NSIndexPath).row]
        default:
            return self.arrayServices[(indexPath as NSIndexPath).row]
        }
    }
    
    fileprivate func generateArrayOfSubscribedServiceIds() -> [Service] {
        guard let subscribedServiceIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] else {
            return [Service]()
        }
        
        let subscribedServiceStatuses = subscribedServiceIds.map { serviceId in
            return self.arrayServices.filter { $0.serviceId == serviceId }.first
        }
        
        return subscribedServiceStatuses.compactMap({ $0 }).sorted(by: { $0.sortOrder < $1.sortOrder })
    }
}

extension ServicesViewController: SearchResultsViewControllerDelegate {
    func didSelectServiceStatus(_ serviceStatus: Service) {
        self.showDetailsForServiceId(serviceStatus.serviceId)
    }
}

extension ServicesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
