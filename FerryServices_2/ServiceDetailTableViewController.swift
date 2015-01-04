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
    
    class Section {
        var title: String
        var rows: [Row]
        
        init (title: String, rows: [Row]) {
            self.title = title
            self.rows = rows
        }
    }
    
    enum Row {
        case Basic(identifier: String, title: String, action: () -> ())
        case Map(identifier: String, action: () -> ())
        case Disruption(identifier: String, disruptionDetails: DisruptionDetails, action: () -> ())
        case NoDisruption(identifier: String, disruptionDetails: DisruptionDetails?, action: () -> ())
        case Loading(identifier: String)
        case TextOnly(identifier: String, text: String, attributedString: NSAttributedString)
    }
    
    struct MainStoryBoard {
        struct TableViewCellIdentifiers {
            static let basicCell = "basicCell"
            static let mapCell = "mapCell"
            static let disruptionsCell = "disruptionsCell"
            static let noDisruptionsCell = "noDisruptionsCell"
            static let loadingCell = "loadingCell"
            static let textOnlyCell = "textOnlyCell"
        }
    }
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapViewCell: UITableViewCell!
    
    var annotations: [MKPointAnnotation]?
    var dataSource: [Section]!
    var refreshing: Bool = false
    var serviceStatus: ServiceStatus!
    
    lazy var locations: [Location]? = {
        if let serviceId = self.serviceStatus.serviceId {
            return Location.fetchLocationsForSericeId(serviceId)
        }
        
        return nil
        }()
    
    // MARK: -
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus.area
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
        
        if let locations = self.locations {
            if locations.count > 0 {
                self.configureMapView()
            }
        }
        
        self.refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        self.refresh()
    }
    
    // MARK: - mapview configuration
    func configureMapView() {
        if let locations = self.locations {
            if locations.count == 0 {
                return
            }
            
            if let annotations = self.annotations {
                self.mapView.removeAnnotations(annotations)
            }
            
            let annotations: [MKPointAnnotation]? = locations.map { location in
                let annotation = MKPointAnnotation()
                annotation.title = location.name
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
                return annotation
            }
            
            self.annotations = annotations
            
            if self.annotations != nil {
                self.mapView.addAnnotations(self.annotations!)
            }
        }
    }
    
    // MARK: - refresh
    func refresh() {
        if self.refreshing {
            return
        }
        
        self.refreshing = true
        
        self.dataSource = generateDatasourceWithDisruptionDetails(nil, refreshing: true)
        self.tableView.reloadData()
        
        self.fetchLatestWeatherDataWithCompletion {
            
        }
        
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
                    [unowned self] in
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
                [unowned self] in
                self.showSummerTimetable()
            })
            timetableRows.append(summerTimetableRow)
        }
        
        // winter timetable
        if isWinterTimetableAvailable() {
            let winterTimetableRow: Row = Row.Basic(identifier: MainStoryBoard.TableViewCellIdentifiers.basicCell, title: "Winter timetable", action: {
                [unowned self] in
                self.showWinterTimetable()
            })
            timetableRows.append(winterTimetableRow)
        }
        
        var route = "Timetable"
        if let actualRoute = serviceStatus.route {
            route = actualRoute
        }
        
        if timetableRows.count > 0 {
            sections.append(Section(title: route, rows: timetableRows))
        }
        
        
        // map section if available
        if let locations = self.locations {
            if locations.count > 0 {
                let mapSection = Section(title: "Map", rows: [Row.Map(identifier: MainStoryBoard.TableViewCellIdentifiers.mapCell, action: {
                    [unowned self] in
                    let mapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("mapViewController") as MapViewController
                    
                    if let actualRoute = self.serviceStatus.route {
                        mapViewController.title = actualRoute
                    }
                    else {
                        mapViewController.title = "Map"
                    }
                    
                    mapViewController.annotations = self.annotations
                    
                    self.navigationController?.pushViewController(mapViewController, animated: true)
                })])
                sections.append(mapSection)
            }
        }
        
        
        //disruption section
        var disruptionRow: Row
        
        if refreshing {
            disruptionRow = Row.Loading(identifier: MainStoryBoard.TableViewCellIdentifiers.loadingCell)
        }
        else if disruptionDetails == nil {
            disruptionRow = Row.TextOnly(identifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell, text: "Unable to fetch the disruption status for this service.", attributedString: NSAttributedString())
        }
        else {
            if let disruptionStatus = disruptionDetails?.disruptionStatus {
                switch disruptionStatus {
                case .Normal:
                    disruptionRow = Row.NoDisruption(identifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell, disruptionDetails: disruptionDetails!, {})
                    
                case .Information:
                    var action: () -> () = {}
                    if disruptionDetails!.hasAdditionalInfo {
                        action = {
                            [unowned self] in
                            let disruptionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WebInformation") as WebInformationViewController
                            disruptionViewController.title = "Additional info"
                            disruptionViewController.html = disruptionDetails!.additionalInfo!
                            self.navigationController?.pushViewController(disruptionViewController, animated: true)
                        }
                    }
                    
                    disruptionRow = Row.NoDisruption(identifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell, disruptionDetails: disruptionDetails!, action)
                    
                case .SailingsAffected, .SailingsCancelled:
                    if let disruptionInfo = disruptionDetails {
                        disruptionRow = Row.Disruption(identifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell, disruptionDetails: disruptionInfo, action: {
                            [unowned self] in
                            let disruptionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WebInformation") as WebInformationViewController
                            disruptionViewController.title = "Disruption information"
                            
                            var disruptionInformation = disruptionInfo.details ?? ""
                            if disruptionDetails!.hasAdditionalInfo {
                                disruptionInformation += "</p>"
                                disruptionInformation += disruptionDetails!.additionalInfo!
                            }
                            
                            disruptionViewController.html = disruptionInformation
                            
                            self.navigationController?.pushViewController(disruptionViewController, animated: true)
                        })
                    }
                    else {
                        disruptionRow = Row.TextOnly(identifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell, text: "Unable to fetch the disruption status for this service.", attributedString: NSAttributedString())
                    }
                }
            }
            else {
                // no disruptionStatus
                disruptionRow = Row.NoDisruption(identifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell, disruptionDetails: nil, {})
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
    
    private func fetchLatestWeatherDataWithCompletion(completion: () -> ()) {
        if let locations = self.locations {
            let location = locations[0]
            switch (location.latitude, location.longitude) {
            case let (.Some(lat), .Some(lng)):
                WeatherAPIClient.sharedInstance.fetchWeatherForLat(lat, lng: lng) { weather, error in
                    println("\(weather)")
                }
            default:
                println("Location does not contain lat and lng")
            }
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
            cell.textLabel!.text = title
            return cell
        case let .Map(identifier):
            return self.mapViewCell!
        case let .Disruption(identifier, disruptionDetails, _):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailDisruptionsTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .NoDisruption(identifier, disruptionDetails, _):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailNoDisruptionTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .Loading(identifier):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailLoadingTableViewCell
            cell.activityIndicatorView.startAnimating()
            return cell
        case let .TextOnly(identifier, text, attributedString):
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailTextOnlyCell
            if text.isEmpty {
                cell.labelText.attributedText = attributedString
            }
            else {
                cell.labelText.text = text
            }
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        switch row {
        case let .Basic(_, _, action):
            action()
        case let .Disruption(_, _, action):
            action()
        case let .Map(_, action):
            action()
        case let .NoDisruption(_, disruptionDetails, action):
            if disruptionDetails != nil && disruptionDetails!.hasAdditionalInfo {
                action()
            }
        default:
            println("No action for cell")
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        mapView.showAnnotations(self.annotations, animated: false)
    }
}
