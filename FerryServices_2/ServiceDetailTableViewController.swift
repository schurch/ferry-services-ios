//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit
import QuickLook

class ServiceDetailTableViewController: UITableViewController, MKMapViewDelegate {
    
    private class Section {
        var title: String
        var rows: [Row]
        
        init (title: String, rows: [Row]) {
            self.title = title
            self.rows = rows
        }
    }
    
    enum Row {
        case Basic(identifier: String, title: String, action: () -> ())
        case Map(identifier: String, [Location])
        case Disruption(identifier: String, DisruptionDetails)
        case NoDisruption(identifier: String)
        case Loading(identifier: String)
        case Error(identifier: String)
    }
    
    struct MainStoryBoard {
        struct TableViewCellIdentifiers {
            static let basicCell = "basicCell"
            static let mapCell = "mapCell"
            static let disruptionsCell = "disruptionsCell"
            static let noDisruptionsCell = "noDisruptionsCell"
            static let loadingCell = "loadingCell"
            static let errorCell = "errorLoadingCell"
        }
    }
    
    private var dataSource: [Section]!
    var refreshing: Bool = false
    var serviceStatus: ServiceStatus!
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus.area
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
        
        self.refresh(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - refresh
    func refresh(sender: UIRefreshControl?) {
        if self.refreshing {
            return
        }
        
        self.refreshing = true
        self.dataSource = generateDatasourceWithDisruptionDetails(nil, refreshing: true)
        self.tableView.reloadData()
        
        self.fetchLatestDisruptionDataWithCompletion {
            self.refreshing = false
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Datasource generation
    private func generateDatasourceWithDisruptionDetails(disruptionDetails: DisruptionDetails?, refreshing: Bool) -> [Section] {
        var sections = [Section]()
        
        // timetable section
        var timetableRows = [Row]()
        
        // depatures if available
        if let routeId = self.serviceStatus.serviceId {
            
            
            if Trip.areTripsAvailableForRouteId(routeId, onOrAfterDate: NSDate()) {
                let departuresRow: Row = Row.Basic(identifier: MainStoryBoard.TableViewCellIdentifiers.basicCell, title: "Departures", action: {
                    if let routeId = self.serviceStatus.serviceId {
                        let timetableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("timetableViewController") as TimetableViewController
                        timetableViewController.routeId = routeId
                        self.navigationController?.pushViewController(timetableViewController, animated: true)
                    }
                })
                timetableRows.append(departuresRow)
            }
        }
        
        // summer timetable
        if isSummerTimetableAvailable() {
            let summerTimetableRow: Row = Row.Basic(identifier: MainStoryBoard.TableViewCellIdentifiers.basicCell, title: "Summer timetable", action: {
                self.showSummerTimetable()
            })
            timetableRows.append(summerTimetableRow)
        }
        
        // winter timetable
        if isWinterTimetableAvailable() {
            let winterTimetableRow: Row = Row.Basic(identifier: MainStoryBoard.TableViewCellIdentifiers.basicCell, title: "Winter timetable", action: {
                self.showWinterTimetable()
            })
            timetableRows.append(winterTimetableRow)
        }
        
        sections.append(Section(title: "Timetable", rows: timetableRows))
        
        
        // map section if available
        if let serviceId = self.serviceStatus.serviceId {
            let locations = Location.fetchLocationsForSericeId(serviceId)
            if locations?.count > 0 {
                let mapSection = Section(title: "Map", rows: [Row.Map(identifier: MainStoryBoard.TableViewCellIdentifiers.mapCell, locations!)])
                sections.append(mapSection)
            }
        }
        
        
        //disruption section
        var disruptionRow: Row
        
        if refreshing {
            disruptionRow = Row.Loading(identifier: MainStoryBoard.TableViewCellIdentifiers.loadingCell)
        }
        else if disruptionDetails == nil {
            disruptionRow = Row.Error(identifier: MainStoryBoard.TableViewCellIdentifiers.errorCell)
        }
        else {
            if let disruptionStatus = disruptionDetails?.disruptionStatus {
                switch disruptionStatus {
                case .Normal, .Information:
                    disruptionRow = Row.NoDisruption(identifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
                case .SailingsAffected, .SailingsCancelled:
                    disruptionRow = Row.Disruption(identifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell, disruptionDetails!)
                }
            }
            else {
                disruptionRow = Row.NoDisruption(identifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
            }
        }
        
        sections.append(Section(title: "Disruptions", rows: [disruptionRow]))
        
        return sections
    }
    
    // MARK: - Utility methods
    private func fetchLatestDisruptionDataWithCompletion(completion: () -> ()) {
        if let serviceId = self.serviceStatus.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                if (error == nil) {
                    self.dataSource = self.generateDatasourceWithDisruptionDetails(disruptionDetails, refreshing: false)
                }
                else {
                    self.dataSource = self.generateDatasourceWithDisruptionDetails(nil, refreshing: false)
                }
                
                completion()
            }
        }
        else {
            completion()
        }
    }
    
    private func isWinterTimetableAvailable() -> Bool {
        if serviceStatus.serviceId == nil {
            return false
        }
        
        return NSFileManager.defaultManager().fileExistsAtPath(winterPath())
    }
    
    private func isSummerTimetableAvailable() -> Bool {
        if serviceStatus.serviceId == nil {
            return false
        }
        
        return NSFileManager.defaultManager().fileExistsAtPath(summerPath())
    }
    
    private func showWinterTimetable() {
        showPDFTimetableAtPath(winterPath(), title: "Winter timetable")
    }
    
    private func showSummerTimetable() {
        showPDFTimetableAtPath(summerPath(), title: "Summer timetable")
    }
    
    private func winterPath() -> String {
        return NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Timetables/2014/Winter/\(serviceStatus.serviceId!).pdf")
    }
    
    private func summerPath() -> String {
        return NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Timetables/2014/Summer/\(serviceStatus.serviceId!).pdf")
    }
    
    private func showPDFTimetableAtPath(path: String, title: String) {
        let previewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TimetablePreview") as TimetablePreviewViewController
        previewViewController.serviceStatus = self.serviceStatus
        previewViewController.url = NSURL(string: path)
        previewViewController.title = title
        self.navigationController?.pushViewController(previewViewController, animated: true)
    }

    // MARK: - UITableViewDatasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].rows.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].title
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
        switch row {
        case let .Basic(identifier, title, _):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
            cell.textLabel.text = title
            return cell
        case let .Map(identifier, locations):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailMapTableViewCell
            cell.mapView.delegate = self
            cell.configureCellForLocations(locations)
            return cell
        case let .Disruption(identifier, disruptionDetails):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailDisruptionsTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .NoDisruption(identifier):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
            return cell
        case let .Loading(identifier):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
            return cell
        case let .Error(identifier):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        switch row {
        case let .Basic(_, _, action):
            action()
        default:
            println("No action for cell")
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}
