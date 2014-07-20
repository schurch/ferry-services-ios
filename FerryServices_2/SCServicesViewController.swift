//
//  SCServicesViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class SCServicesViewController: UITableViewController {
    
    struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let serviceStatusCell = "serviceStatusCell"
        }
    }
    
    var arrayServiceStatuses = [SCServiceStatus]()
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        self.refresh(nil)
    }
    
    // MARK: methods
    func refresh(sender: UIRefreshControl?) {
        SCAPIClient.sharedInstance.fetchFerryServicesWithCompletion({ serviceStatuses, error in
            if let statuses = serviceStatuses {
                self.arrayServiceStatuses = statuses
            }
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        })
    }
    
    // MARK: tableview datasource
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return arrayServiceStatuses.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let serviceStatusCell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.serviceStatusCell, forIndexPath: indexPath) as SCServiceStatusTableViewCell
        
        let serviceStatus = arrayServiceStatuses[indexPath.row]
        
        serviceStatusCell.labelTitle.text = serviceStatus.area
        serviceStatusCell.labelSubtitle.text = serviceStatus.route
        
        switch serviceStatus.disruptionStatus! {
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
        
        return serviceStatusCell
    }

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
