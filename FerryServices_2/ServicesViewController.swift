//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class ServicesViewController: UITableViewController {
    
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCell"
        }
    }
    
    private var arrayServiceStatuses = [ServiceStatus]()
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        tableView.contentOffset = CGPoint(x: 0, y: -60)
        self.refreshControl.beginRefreshing()
        
        self.refresh(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow(), animated: true)
    }
    
    // MARK: - notifications
    internal func applicationDidBecomeActive(notification: NSNotification) {
        self.refresh(nil)
    }
    
    // MARK: - refresh
    func refresh(sender: UIRefreshControl?) {
        APIClient.sharedInstance.fetchFerryServicesWithCompletion { serviceStatuses, error in
            if let statuses = serviceStatuses {
                self.arrayServiceStatuses = statuses
            }
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    // MARK: - tableview datasource
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return arrayServiceStatuses.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let serviceStatusCell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, forIndexPath: indexPath) as ServiceStatusTableViewCell
        
        let serviceStatus = arrayServiceStatuses[indexPath.row]
        
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
    
    // MARK: - storyboard
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        let serviceDetailViewController = segue.destinationViewController as ServiceDetailTableViewController;
        let indexPath = self.tableView.indexPathForSelectedRow()
        let serviceStatus = self.arrayServiceStatuses[indexPath.row]
        serviceDetailViewController.serviceStatus = serviceStatus
    }
}
