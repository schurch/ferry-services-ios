//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimetableTimeTableViewCellDelegate {
    
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let dateCell = "dateCell"
            static let timeCell = "timeCell"
            static let datePickerCell = "datePickerCell"
        }
    }
    
    private let TimetableHeaderIdentifier = "header"
    
    @IBOutlet var tableView: UITableView!
    
    var date: NSDate!
    var routeId: Int!
    var arrayOfRoutes: [Route]?

    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Departures"
        
        self.tableView.sectionHeaderHeight = 44
        self.tableView.registerNib(UINib(nibName: "TimetableHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: TimetableHeaderIdentifier)
        
        self.date = NSDate()
        
        if self.routeId != nil && self.date != nil {
            self.arrayOfRoutes = Route.fetchRoutesForServiceId(self.routeId, date: self.date)?.filter { $0.trips?.count > 0 }
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - uitableview datasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let routes = self.arrayOfRoutes {
            return routes.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let route = self.arrayOfRoutes?[section] {
            if let trips = route.trips {
                return trips.count
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.timeCell) as TimetableTimeTableViewCell
        
        cell.delegate = self
        
        if let trip = self.arrayOfRoutes?[indexPath.section].trips?[indexPath.row] {
            cell.labelTime.text = trip.deparuteTime
            cell.labelTimeCounterpart.text = "arriving at \(trip.arrivalTime)"
            
            if let notes = trip.notes?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
                if countElements(notes) > 0 {
                    cell.buttonInfo.hidden = false
                }
                else {
                    cell.buttonInfo.hidden = true
                }
            }
        }
        
        return cell
    }
    
    // MARK: - uitableview delegate
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(TimetableHeaderIdentifier) as TimetableHeaderView
        
        if let route = self.arrayOfRoutes?[section] {
            headerView.labelHeader.text = route.routeDescription()
            
            if let routeType = route.routeType {
                var image :UIImage
                switch routeType {
                case .Ferry:
                    image = UIImage(named: "ferry_icon")
                case .Train:
                    image = UIImage(named: "train_icon")
                }
                
                headerView.imageViewTransportType.image = image
            }
        }
        
        return headerView
    }
    
    // MARK: - timetable time cell delegate
    func didTouchTimetableInfoButtonForCell(cell: TimetableTimeTableViewCell) {
        
    }
}
