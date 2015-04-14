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

class ServiceDetailTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    
    class Section {
        var title: String?
        var footer: String?
        var rows: [Row]
        
        var showHeader: Bool
        var showFooter: Bool
        
        init (title: String?, footer: String?, rows: [Row]) {
            self.title = title
            self.footer = footer
            self.rows = rows
            self.showHeader = true
            self.showFooter =  true
        }
    }
    
    enum Row {
        case Basic(title: String, subtitle: String?, action: (() -> ())?)
        case Disruption(disruptionDetails: DisruptionDetails, action: () -> ())
        case NoDisruption(disruptionDetails: DisruptionDetails?, action: () -> ())
        case Loading
        case TextOnly(text: String)
        case Weather(location: Location)
        case Alert
    }
    
    struct MainStoryBoard {
        struct TableViewCellIdentifiers {
            static let basicCell = "basicCell"
            static let disruptionsCell = "disruptionsCell"
            static let noDisruptionsCell = "noDisruptionsCell"
            static let loadingCell = "loadingCell"
            static let textOnlyCell = "textOnlyCell"
            static let weatherCell = "weatherCell"
            static let alertCell = "alertCell"
        }
        struct Constants {
            static let headerMargin = CGFloat(16)
            static let contentInset = CGFloat(120)
            static let motionEffectAmount = CGFloat(10)
        }
    }
    
    @IBOutlet weak var constraintMapViewLeading: NSLayoutConstraint!
    @IBOutlet weak var constraintMapViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintMapViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var labelArea: UILabel!
    @IBOutlet weak var labelRoute: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var alertCell: ServiceDetailReceiveAlertCellTableViewCell!
    
    var annotations: [MKPointAnnotation]?
    var dataSource: [Section] = []
    var mapMotionEffect: UIMotionEffectGroup!
    var refreshingDisruptionInfo: Bool = true // show table as refreshing initially
    var serviceStatus: ServiceStatus!
    var disruptionDetails: DisruptionDetails?
    var headerHeight: CGFloat!
    var viewBackground: UIView!
    
    lazy var parseChannel: String = {
        return "\(AppConstants.parseChannelPrefix)\(self.serviceStatus.serviceId!)"
    }()
    
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
        
        // configure header
        self.labelArea.text = self.serviceStatus.area
        self.labelRoute.text = self.serviceStatus.route
        
        self.labelArea.preferredMaxLayoutWidth = self.view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
        self.labelRoute.preferredMaxLayoutWidth = self.view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
        
        self.tableView.tableHeaderView!.setNeedsLayout()
        self.tableView.tableHeaderView!.layoutIfNeeded()
        
        self.headerHeight = self.tableView.tableHeaderView!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        self.tableView.tableHeaderView!.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.headerHeight)
        
        // if the visualeffect view goes past the top of the screen we want to keep showing mapview blur
        self.constraintMapViewTop.constant = -self.headerHeight
        
        // configure tableview
        self.tableView.backgroundColor = UIColor.clearColor()
        self.tableView.contentInset = UIEdgeInsetsMake(MainStoryBoard.Constants.contentInset, 0, 0, 0)
        
        self.viewBackground = UIView(frame: CGRectMake(0, self.headerHeight, self.view.bounds.size.width, self.view.bounds.size.height))
        self.viewBackground.backgroundColor = UIColor.tealBackgroundColor()
        self.tableView.addSubview(self.viewBackground)
        self.tableView.sendSubviewToBack(self.viewBackground)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.tableView.registerNib(UINib(nibName: "DisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell)
        self.tableView.registerNib(UINib(nibName: "NoDisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
        self.tableView.registerNib(UINib(nibName: "TextOnlyCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell)
        
        // alert cell
        self.alertCell = UINib(nibName: "AlertCell", bundle: nil).instantiateWithOwner(nil, options: nil).first as ServiceDetailReceiveAlertCellTableViewCell
        self.alertCell.switchAlert.addTarget(self, action: Selector("alertSwitchChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        self.alertCell.configureLoading()
        
        PFPush.getSubscribedChannelsInBackgroundWithBlock { [unowned self] (channels, error) in
            if channels != nil {
                self.alertCell.configureLoadedWithSwitchOn(channels.containsObject(self.parseChannel))
            }
            else {
                self.alertCell.configureLoadedWithSwitchOn(false)
            }
        }
        
        // map button
        let mapButton = UIButton(frame: CGRectMake(0, -MainStoryBoard.Constants.contentInset, self.view.bounds.size.width, self.view.bounds.size.height))
        mapButton.addTarget(self, action: "touchedButtonShowMap:", forControlEvents: UIControlEvents.TouchUpInside)
        self.tableView.addSubview(mapButton)
        self.tableView.sendSubviewToBack(mapButton)
        
        // map motion effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
        horizontalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
        
        let vertiacalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
        vertiacalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
        vertiacalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
        
        self.mapMotionEffect = UIMotionEffectGroup()
        self.mapMotionEffect.motionEffects = [horizontalMotionEffect, vertiacalMotionEffect]
        self.mapView.addMotionEffect(self.mapMotionEffect)
        
        // extend edges of map as motion effect will move them
        self.constraintMapViewLeading.constant = -MainStoryBoard.Constants.motionEffectAmount
        self.constraintMapViewTrailing.constant = -MainStoryBoard.Constants.motionEffectAmount
        
        self.configureMapView()
        self.initializeTable()
        self.refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // clip bounds so map doesn't expand over the edges when we animated to/from view
        self.view.clipsToBounds = true
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // don't clip bounds as map extends past top allowing blur view to be pushed up and not 
        // have nasty effect as it gets near top
        self.view.clipsToBounds = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // clip bounds so map doesn't expand over the edges when we animated to/from view
        self.view.clipsToBounds = true
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
    
    // MARK: - ui actions
    @IBAction func touchedButtonShowMap(sender: UIButton) {
        self.showMap()
    }
    
    func alertSwitchChanged(switchState: UISwitch) {
        let currentInstallation = PFInstallation.currentInstallation()
        let isSwitchOn = switchState.on
        
        if isSwitchOn {
            currentInstallation.addUniqueObject(self.parseChannel, forKey: "channels")
        } else {
            currentInstallation.removeObject(self.parseChannel, forKey: "channels")
        }
        
        self.alertCell.configureLoading()
        currentInstallation.saveInBackgroundWithBlock { [unowned self] (succeeded, error)  in
            if succeeded {
                self.alertCell.configureLoadedWithSwitchOn(isSwitchOn)
            }
            else {
                self.alertCell.configureLoadedWithSwitchOn(!isSwitchOn)
            }
        }
    }
    
    // MARK: - refresh
    func refresh() {
        self.fetchLatestWeatherData()
        self.fetchLatestDisruptionData()
    }
    
    // MARK: - Datasource generation
    private func generateDatasource() {
        var sections = [Section]()
        
        //disruption section
        var disruptionRow: Row
        var footer: String?
        
        if self.refreshingDisruptionInfo {
            disruptionRow = Row.Loading
        }
        else if self.disruptionDetails == nil {
            disruptionRow = Row.TextOnly(text: "Unable to fetch the disruption status for this service.")
        }
        else {
            if let disruptionStatus = self.disruptionDetails?.disruptionStatus {
                switch disruptionStatus {
                case .Normal:
                    disruptionRow = Row.NoDisruption(disruptionDetails: disruptionDetails!, {})
                    
                case .Information:
                    var action: () -> () = {}
                    if self.disruptionDetails!.hasAdditionalInfo {
                        action = {
                            [unowned self] in
                            Flurry.logEvent("Show additional info")
                            self.showWebInfoViewWithTitle("Additional info", content: self.disruptionDetails!.additionalInfo!)
                        }
                    }
                    
                    disruptionRow = Row.NoDisruption(disruptionDetails: disruptionDetails!, action)
                    
                case .SailingsAffected, .SailingsCancelled:
                    if let disruptionInfo = disruptionDetails {
                        footer = disruptionInfo.lastUpdated
                        
                        disruptionRow = Row.Disruption(disruptionDetails: disruptionInfo, action: {
                            [unowned self] in
                            Flurry.logEvent("Show disruption information")
                            
                            var disruptionInformation = disruptionInfo.details ?? ""
                            if self.disruptionDetails!.hasAdditionalInfo {
                                disruptionInformation += "</p>"
                                disruptionInformation += self.disruptionDetails!.additionalInfo!
                            }
                            
                            self.showWebInfoViewWithTitle("Disruption information", content:disruptionInformation)
                        })
                    }
                    else {
                        disruptionRow = Row.TextOnly(text: "Unable to fetch the disruption status for this service.")
                    }
                }
            }
            else {
                // no disruptionStatus
                disruptionRow = Row.NoDisruption(disruptionDetails: nil, {})
            }
        }
        
        let alertRow = Row.Alert
        
        let disruptionSection = Section(title: nil, footer: footer, rows: [disruptionRow, alertRow])
        sections.append(disruptionSection)
        
        // timetable section
        var timetableRows = [Row]()
        
        // depatures if available
        if let routeId = self.serviceStatus.serviceId {
            if Trip.areTripsAvailableForRouteId(routeId, onOrAfterDate: NSDate()) {
                let departuresRow: Row = Row.Basic(title: "Departures", subtitle: nil,  action: {
                    [unowned self] in
                    self.showDepartures()
                })
                timetableRows.append(departuresRow)
            }
        }
        
        // winter timetable
        if isWinterTimetableAvailable() {
            let winterTimetableRow: Row = Row.Basic(title: "Winter timetable", subtitle: nil, action: {
                [unowned self] in
                self.showWinterTimetable()
            })
            timetableRows.append(winterTimetableRow)
        }
        
        // summer timetable
        if isSummerTimetableAvailable() {
            let summerTimetableRow: Row = Row.Basic(title: "Summer timetable", subtitle: nil, action: {
                [unowned self] in
                self.showSummerTimetable()
            })
            timetableRows.append(summerTimetableRow)
        }
        
        var route = "Timetable"
        if let actualRoute = serviceStatus.route {
            route = actualRoute
        }
        
        if timetableRows.count > 0 {
            let timetableSection = Section(title: "Timetables", footer: nil, rows: timetableRows)
            sections.append(timetableSection)
        }
        
        // weather sections
        if let locations = self.locations {
            for location in locations {
                var weatherRows = [Row]()
                
                switch (location.latitude, location.longitude) {
                case let (.Some(lat), .Some(lng)):
                    let weatherRow = Row.Weather(location: location)
                    weatherRows.append(weatherRow)
                    sections.append(Section(title: location.name, footer: nil, rows: weatherRows))
                default:
                    break;
                }
            }
        }
        
        self.dataSource = sections
    }
    
    // MARK: - Utility methods
    private func initializeTable() {
        self.generateDatasource()
        self.tableView.reloadData()
        
        var backgroundViewFrame = self.viewBackground.frame
        backgroundViewFrame.size.height = self.tableView.contentSize.height + (UIScreen.mainScreen().bounds.size.height)
        self.viewBackground.frame = backgroundViewFrame
    }
    
    private func fetchLatestDisruptionData() {
        let reloadServiceInfo: () -> () = {
            self.refreshingDisruptionInfo = false
            self.generateDatasource()
            
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        }
        
        if let serviceId = self.serviceStatus.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, _, _ in
                self.disruptionDetails = disruptionDetails
                reloadServiceInfo()
            }
        }
        else {
            reloadServiceInfo()
        }
    }
    
    private func fetchLatestWeatherData() {
        if let locations = self.locations {
            for location in locations {
                WeatherAPIClient.sharedInstance.fetchWeatherForLocation(location) { weather, error in
                    location.weather = weather
                    location.weatherFetchError = error
                    self.reloadWeatherForLocation(location)
                }
            }
        }
    }
    
    private func reloadWeatherForLocation(location: Location) {
        if let indexPath = self.indexPathForLocation(location) {
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    private func indexPathForLocation(location: Location) -> NSIndexPath? {
        var sectionCount = 0
        
        for section in self.dataSource {
            
            var rowCount = 0
            for row in section.rows {
                switch row {
                case let .Weather(rowLocation):
                    if location == rowLocation {
                        return NSIndexPath(forRow: rowCount, inSection: sectionCount)
                    }
                default:
                    break
                }
                
                rowCount += 1
            }
            
            sectionCount += 1
        }
        
        return nil
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
        Flurry.logEvent("Show winter timetable")
        showPDFTimetableAtPath(winterPath(), title: "Winter timetable")
    }
    
    private func showSummerTimetable() {
        Flurry.logEvent("Show summer timetable")
        showPDFTimetableAtPath(summerPath(), title: "Summer timetable")
    }
    
    private func winterPath() -> String {
        return NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Timetables/2014/Winter/\(serviceStatus.serviceId!).pdf")
    }
    
    private func summerPath() -> String {
        return NSBundle.mainBundle().bundlePath.stringByAppendingPathComponent("Timetables/2015/Summer/\(serviceStatus.serviceId!).pdf")
    }
    
    private func showPDFTimetableAtPath(path: String, title: String) {
        let previewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TimetablePreview") as TimetablePreviewViewController
        previewViewController.serviceStatus = self.serviceStatus
        previewViewController.url = NSURL(string: path)
        previewViewController.title = title
        self.navigationController?.pushViewController(previewViewController, animated: true)
    }
    
    private func showMap() {
        Flurry.logEvent("Show map")
        let mapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("mapViewController") as MapViewController
        
        if let actualRoute = self.serviceStatus.route {
            mapViewController.title = actualRoute
        }
        else {
            mapViewController.title = "Map"
        }
        
        mapViewController.annotations = self.annotations
        self.navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    private func showDepartures() {
        Flurry.logEvent("Show departures")
        if let routeId = self.serviceStatus.serviceId {
            let timetableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("timetableViewController") as TimetableViewController
            timetableViewController.routeId = routeId
            self.navigationController?.pushViewController(timetableViewController, animated: true)
        }
    }
    
    private func showWebInfoViewWithTitle(title: String, content: String) {
        let disruptionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WebInformation") as WebInformationViewController
        disruptionViewController.title = title
        disruptionViewController.html = content
        self.navigationController?.pushViewController(disruptionViewController, animated: true)
    }

    private func calculateMapRectForAnnotations(annotations: [MKPointAnnotation]) -> MKMapRect {
        var mapRect = MKMapRectNull
        for annotation in annotations {
            let point = MKMapPointForCoordinate(annotation.coordinate)
            mapRect = MKMapRectUnion(mapRect, MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
        }
        return mapRect
    }

    
    // MARK: - UITableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].rows.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].title
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return dataSource[section].footer
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
        switch row {
        case let .Basic(title, subtitle, action):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.basicCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
            cell.textLabel!.text = title
            
            if let subtitle = subtitle {
                cell.detailTextLabel!.text = subtitle
            }
            else {
                cell.detailTextLabel!.text = ""
            }
            
            cell.accessoryType = action == nil ? .None : .DisclosureIndicator
            
            return cell
        case let .Disruption(disruptionDetails, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.disruptionsCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailDisruptionsTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .NoDisruption(disruptionDetails, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailNoDisruptionTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .Loading:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.loadingCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailLoadingTableViewCell
            cell.activityIndicatorView.startAnimating()
            return cell
        case let .TextOnly(text):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.textOnlyCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailTextOnlyCell
            cell.labelText.text = text
            return cell
        case let .Weather(location):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.weatherCell
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as ServiceDetailWeatherCell
            cell.selectionStyle = .None
            cell.configureWithLocation(location)
            return cell
        case let .Alert:
            return self.alertCell
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .Basic:
            return 44.0
        case let .Disruption(disruptionDetails, _):
            let height = ServiceDetailDisruptionsTableViewCell.heightWithDisruptionDetails(disruptionDetails, tableView: tableView)
            return height
        case let .NoDisruption(disruptionDetails, _):
            let height = ServiceDetailNoDisruptionTableViewCell.heightWithDisruptionDetails(disruptionDetails, tableView: tableView)
            return height
        case .Loading:
            return 55.0
        case let .TextOnly(text):
            let height = ServiceDetailTextOnlyCell.heightWithText(text, tableView: tableView)
            return height
        case .Weather:
            return 84.0
        case .Alert:
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        switch row {
        case let .Basic(_, _, possibleAction):
            if let action = possibleAction {
                action()
            }
        case let .Disruption(_, action):
            action()
        case let .NoDisruption(disruptionDetails, action):
            if disruptionDetails != nil && disruptionDetails!.hasAdditionalInfo {
                action()
            }
        default:
            break;
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
        switch row {
        case let .Weather(_):
            if let weatherCell = cell as? ServiceDetailWeatherCell {
                weatherCell.viewSeparator.backgroundColor = tableView.separatorColor
            }
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.tealTextColor()
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource[section].showHeader {
            return UITableViewAutomaticDimension
        }
        else {
            return CGFloat.min
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if dataSource[section].showFooter {
            return UITableViewAutomaticDimension
        }
        else {
            return CGFloat.min
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        let rect = self.calculateMapRectForAnnotations(self.annotations!)
        let topInset = MainStoryBoard.Constants.contentInset + 20
        let bottomInset = self.mapView.frame.size.height - (MainStoryBoard.Constants.contentInset * 2) + 60
        let visibleRect = self.mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsetsMake(topInset, 35, bottomInset, 35))
        self.mapView.setVisibleMapRect(visibleRect, animated: false)
    }
}
