//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServicesViewController: UITableViewController {
    
    private struct TableViewSections {
        static let subscribed = 0
        static let services = 1
    }
    
    private var arrayServices = Service.defaultServices
    private var arraySubscribedServices = [Service]()
    private var searchController: UISearchController!
    private var searchResultsController: SearchResultsViewController!
    
    // MARK: -
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Services"
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServicesViewController.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: ServiceStatusCell.reuseID)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        searchResultsController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsController") as! SearchResultsViewController)
        searchResultsController.arrayOfServices = Service.defaultServices
        searchResultsController.didSelectService = { [weak self] service in
            self?.showDetails(for: service)
        }
        
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
        
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        arraySubscribedServices = createSubscribedServices()
        tableView.reloadData()
    }
    
    // MARK: - Notifications
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        refresh()
    }
    
    // MARK: - Refresh
    @objc func refresh() {
        API.fetchServices { result in
            self.refreshControl?.endRefreshing()
            
            guard case let .success(services) = result else {
                return
            }

            self.arrayServices = services.sorted(by: { $0.sortOrder < $1.sortOrder })
            self.arraySubscribedServices = self.createSubscribedServices()
            self.searchResultsController.arrayOfServices = self.arrayServices

            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return arraySubscribedServices.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if arraySubscribedServices.isEmpty {
            return nil
        }
        
        return section == TableViewSections.subscribed ? "Subscribed" : "Services"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if arraySubscribedServices.isEmpty {
            return arrayServices.count
        }
        
        return section == TableViewSections.subscribed ? arraySubscribedServices.count : arrayServices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serviceStatusCell = tableView.dequeueReusableCell(withIdentifier: "serviceStatusCellReuseId", for: indexPath) as! ServiceStatusCell
        let serviceStatus = serviceForTableView(tableView, indexPath: indexPath)
        serviceStatusCell.configureCellWithServiceStatus(serviceStatus)
        
        return serviceStatusCell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor(named: "Text")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = serviceForTableView(tableView, indexPath: indexPath)
        showDetails(for: service)
    }
    
    // MARK: - Helpers
    private func serviceForTableView(_ tableView: UITableView, indexPath: IndexPath) -> Service {
        if arraySubscribedServices.isEmpty {
            return arrayServices[indexPath.row]
        }
        
        return indexPath.section == TableViewSections.subscribed
            ? arraySubscribedServices[indexPath.row]
            : arrayServices[indexPath.row]
    }
    
    private func createSubscribedServices() -> [Service] {
        guard let subscribedServiceIDs = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] else {
            return []
        }
        
        return subscribedServiceIDs
            .map { serviceID in
                self.arrayServices.first(where: { service in service.serviceId == serviceID })
            }
            .compactMap { $0 }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }
    
    private func showDetails(for service: Service) {
        let serviceDetailViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServiceDetailTableViewController") as! ServiceDetailTableViewController
        serviceDetailViewController.service = service
        self.navigationController?.pushViewController(serviceDetailViewController, animated: true)
    }
}

extension ServicesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
