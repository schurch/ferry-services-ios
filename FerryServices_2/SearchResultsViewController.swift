//
//  SearchResultsViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit

protocol SearchResultsViewControllerDelegate: class {
    func didSelectServiceStatus(_ serviceStatus: Service)
}

class SearchResultsViewController: UIViewController {
    
    static let serviceStatusReuseId = "serviceStatusCellReuseId"
    
    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfServices: [Service] = []
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    fileprivate var arrayOfFilteredServices: [Service] = []
    fileprivate var bottomInset: CGFloat = 0.0
    fileprivate var previewingIndexPath: IndexPath?
    fileprivate var text: String?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: SearchResultsViewController.serviceStatusReuseId)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardShownNotification(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardWillBeHiddenNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    fileprivate func configureView() {
        guard self.isViewLoaded else {
            return
        }
        
        self.configureListView()
    }
    
    fileprivate func configureListView() {
        self.filterResults()
        self.tableView.reloadData()
    }
    
    // MARK: - Public
    @objc func keyboardShownNotification(_ notification: Notification) {
        if let height = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height {
            let inset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: height, right: 0.0)
            self.tableView.contentInset = inset
            self.tableView.scrollIndicatorInsets = inset
            
            self.bottomInset = height + 10.0
        }
    }
    
    @objc func keyboardWillBeHiddenNotification(_ notification: Notification) {
        self.tableView.contentInset = UIEdgeInsets.zero
        self.tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        self.bottomInset = 0.0
    }
    
    // MARK: - Utility methods
    fileprivate func filterResults() {
        guard let filterText = self.text else {
            return
        }
        
        self.arrayOfFilteredServices = self.arrayOfServices.filter { service in
            var containsArea = false
            containsArea = service.area.lowercased().contains(filterText.lowercased())
            
            var containsRoute = false
            containsRoute = service.route.lowercased().contains(filterText.lowercased())
            
            return containsArea || containsRoute
        }
        
        self.tableView.reloadData()
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
