//
//  SearchResultsViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/11/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController {
        
    @IBOutlet weak var tableView: UITableView!
    
    var arrayOfServices: [Service] = []
    
    var didSelectService: ((Service) -> ())?
    
    private var arrayOfFilteredServices: [Service] = []
    private var bottomInset: CGFloat = 0.0
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ServiceStatusCell", bundle: nil), forCellReuseIdentifier: ServiceStatusCell.reuseID)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardShownNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultsViewController.keyboardWillBeHiddenNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - Public
    @objc func keyboardShownNotification(_ notification: Notification) {
        if let height = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height {
            let inset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: height, right: 0.0)
            tableView.contentInset = inset
            tableView.scrollIndicatorInsets = inset
            
            bottomInset = height + 10.0
        }
    }
    
    @objc func keyboardWillBeHiddenNotification(_ notification: Notification) {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        bottomInset = 0.0
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        
        arrayOfFilteredServices = arrayOfServices.filter { service in
            let containsArea = service.area.lowercased().contains(text.lowercased())
            let containsRoute = service.route.lowercased().contains(text.lowercased())
            return containsArea || containsRoute
        }
        
        tableView.reloadData()
    }
}

extension SearchResultsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfFilteredServices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serviceStatusCell = tableView.dequeueReusableCell(withIdentifier: ServiceStatusCell.reuseID, for: indexPath) as! ServiceStatusCell
        let service = arrayOfFilteredServices[indexPath.row]
        serviceStatusCell.configureCellWithService(service)
        
        return serviceStatusCell
    }
}

extension SearchResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectService?(arrayOfFilteredServices[indexPath.row])
    }
}
