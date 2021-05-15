//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServicesViewController: UITableViewController {
    
    struct Section {
        let header: String?
        let rows: [Service]
    }
    
    private var tableData: [Section] = ServicesViewController.generateTableData(from: Service.defaultServices)
    private var services: [Service] = Service.defaultServices
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
        searchResultsController.arrayOfServices = services
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
        
        tableData = ServicesViewController.generateTableData(from: services)
        tableView.reloadData()
    }
    
    // MARK: - Notifications
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        refresh()
    }
    
    // MARK: - Refresh
    @objc func refresh() {
        APIClient.fetchServices { result in
            self.refreshControl?.endRefreshing()
            
            guard case let .success(services) = result else {
                return
            }

            self.services = services.sorted(by: { $0.sortOrder < $1.sortOrder })
            self.searchResultsController.arrayOfServices = self.services
            self.tableData = ServicesViewController.generateTableData(from: self.services)
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].header
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serviceCell = tableView.dequeueReusableCell(withIdentifier: "serviceStatusCellReuseId", for: indexPath) as! ServiceStatusCell
        let service = tableData[indexPath.section].rows[indexPath.row]
        serviceCell.configureCellWithService(service)
        
        return serviceCell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor(named: "Text")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service = tableData[indexPath.section].rows[indexPath.row]
        showDetails(for: service)
    }
    
    // MARK: - Helpers
    private static func generateTableData(from services: [Service], userDefaults: UserDefaults = UserDefaults.standard) -> [Section] {
        let subscribedServices = ServicesViewController.createSubscribedServices(from: services, userDefaults: userDefaults)
        if subscribedServices.count > 0 {
            return [Section(header: "Subscribed", rows: subscribedServices), Section(header: "Services", rows: services)]
        } else {
            return [Section(header: nil, rows: services)]
        }
    }
    
    private static func createSubscribedServices(from services: [Service], userDefaults: UserDefaults) -> [Service] {
        guard let subscribedServiceIDs = userDefaults.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] else {
            return []
        }
        
        return subscribedServiceIDs
            .map { serviceID in
                services.first(where: { service in service.serviceId == serviceID })
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
