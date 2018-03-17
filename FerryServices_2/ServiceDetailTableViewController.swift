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
import Parse

typealias ViewControllerGenerator = () -> UIViewController?

class ServiceDetailTableViewController: UIViewController {
    
    enum ViewConfiguration {
        case previewing
        case full
    }
    
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
        case basic(title: String, subtitle: String?, viewControllerGenerator: ViewControllerGenerator)
        case disruption(disruptionDetails: DisruptionDetails, viewControllerGenerator: ViewControllerGenerator)
        case noDisruption(disruptionDetails: DisruptionDetails?, viewControllerGenerator: ViewControllerGenerator)
        case loading
        case textOnly(text: String)
        case weather(location: Location)
        case alert
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
            static let motionEffectAmount = CGFloat(20)
        }
    }
    
    @IBOutlet weak var constraintMapViewLeading: NSLayoutConstraint!
    @IBOutlet weak var constraintMapViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintMapViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var labelArea: UILabel!
    @IBOutlet weak var labelRoute: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var alertCell: ServiceDetailReceiveAlertCellTableViewCell = UINib(nibName: "AlertCell", bundle: nil).instantiate(withOwner: nil, options: nil).first as! ServiceDetailReceiveAlertCellTableViewCell
    
    var mapViewDelegate: ServiceMapDelegate?
    var dataSource: [Section] = []
    var disruptionDetails: DisruptionDetails?
    var headerHeight: CGFloat?
    var mapMotionEffect: UIMotionEffectGroup!
    var mapRectSet = false
    var refreshingDisruptionInfo: Bool = true // show table as refreshing initially
    var serviceStatus: ServiceStatus!
    var viewBackground: UIView!
    var viewConfiguration: ViewConfiguration = .full
    var windAnimationTimer: Timer!
    
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
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus.area
        
        self.labelArea.text = self.serviceStatus.area
        self.labelRoute.text = self.serviceStatus.route
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServiceDetailTableViewController.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        if viewConfiguration == .full {
            LastViewedServices.register(self.serviceStatus)
            
            // configure tableview
            self.tableView.contentInset = UIEdgeInsetsMake(MainStoryBoard.Constants.contentInset, 0, 0, 0)
            
            // alert cell
            self.alertCell.switchAlert.addTarget(self, action: #selector(ServiceDetailTableViewController.alertSwitchChanged(_:)), for: UIControlEvents.valueChanged)
            self.alertCell.configureLoading()
            
            PFPush.getSubscribedChannelsInBackground { [weak self] (channels, error) in
                guard self != nil else {
                    // self might be nil if we've popped the view controller when the completion block is called
                    return
                }
                
                guard let channels = channels else {
                    self!.alertCell.configureLoadedWithSwitchOn(false)
                    self?.removeServiceIdFromSubscribedList()
                    return
                }
                
                let subscribed = channels.contains(self!.parseChannel)
                self!.alertCell.configureLoadedWithSwitchOn(subscribed)
                
                if subscribed {
                    self?.addServiceIdToSubscribedList()
                }
                else {
                    self?.removeServiceIdFromSubscribedList()
                }
            }
            
            // map motion effect
            let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.tiltAlongHorizontalAxis)
            horizontalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
            horizontalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
            
            let vertiacalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.tiltAlongVerticalAxis)
            vertiacalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
            vertiacalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
            
            self.mapMotionEffect = UIMotionEffectGroup()
            self.mapMotionEffect.motionEffects = [horizontalMotionEffect, vertiacalMotionEffect]
            self.mapView.addMotionEffect(self.mapMotionEffect)
            
            // extend edges of map as motion effect will move them
            self.constraintMapViewLeading.constant = -MainStoryBoard.Constants.motionEffectAmount
            self.constraintMapViewTrailing.constant = -MainStoryBoard.Constants.motionEffectAmount
            self.constraintMapViewTop.constant = -MainStoryBoard.Constants.motionEffectAmount
            
            if let locations = self.locations {
                mapViewDelegate = ServiceMapDelegate(mapView: mapView, locations: locations, showVessels: true)
                mapViewDelegate?.shouldAllowAnnotationSelection = false
                mapView.delegate = mapViewDelegate
                
                if let portAnnotations = mapViewDelegate?.portAnnotations {
                    LastViewedServices.registerMapSnapshot(portAnnotations)
                }
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(touchedButtonShowMap(_:)))
            self.tableView.backgroundView = UIView()
            self.tableView.backgroundView?.addGestureRecognizer(tap)
        }
        else {
            mapView.removeFromSuperview()
        }
        
        let backgroundViewFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        viewBackground = UIView(frame: backgroundViewFrame)
        viewBackground.backgroundColor = UIColor.tealBackgroundColor()
        view.insertSubview(viewBackground, belowSubview: tableView)
        
        self.tableView.backgroundColor = UIColor.clear
        
        self.tableView.register(UINib(nibName: "DisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell)
        self.tableView.register(UINib(nibName: "NoDisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
        self.tableView.register(UINib(nibName: "TextOnlyCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell)
        self.tableView.register(UINib(nibName: "WeatherCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.weatherCell)
        
        self.initializeTable()
        self.refresh()
        
        registerForPreviewing(with: self, sourceView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // clip bounds so map doesn't expand over the edges when we animated to/from view
        self.view.clipsToBounds = true
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        self.windAnimationTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ServiceDetailTableViewController.animateWindVanes), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // don't clip bounds as map extends past top allowing blur view to be pushed up and not
        // have nasty effect as it gets near top
        self.view.clipsToBounds = false
        
        self.mapViewDelegate?.refresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // clip bounds so map doesn't expand over the edges when we animated to/from view
        self.view.clipsToBounds = true
        
        self.windAnimationTimer.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.headerHeight == nil {
            // Configure the headerview once we know we know the size of the view
            self.labelArea.preferredMaxLayoutWidth = self.view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
            self.labelRoute.preferredMaxLayoutWidth = self.view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
            
            self.tableView.tableHeaderView!.setNeedsLayout()
            self.tableView.tableHeaderView!.layoutIfNeeded()
            let headerHeight = self.tableView.tableHeaderView!.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            self.tableView.tableHeaderView!.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: headerHeight)
            
            var frame = viewBackground.frame
            frame.origin.y = -tableView.contentOffset.y + headerHeight
            viewBackground.frame = frame
            
            self.headerHeight = headerHeight
        }
        
        if !mapRectSet {
            // Need to do this at this point as we need to know the size of the view to calculate the rect that is shown
            setMapVisibleRect()
            mapRectSet = true
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Scroll the viewBackground with the tableview as it's transparent
        guard let viewBackground = viewBackground else { return }
        guard let headerHeight = headerHeight else { return }
        let y = -scrollView.contentOffset.y
        var frame = viewBackground.frame
        frame.origin.y = y + headerHeight
        viewBackground.frame = frame
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        self.refresh()
    }

    // MARK: - ui actions
    @IBAction func touchedButtonShowMap(_ sender: UIButton) {
        show(mapViewController(), sender: self)
    }
    
    @objc func alertSwitchChanged(_ switchState: UISwitch) {
        let currentInstallation = PFInstallation.current()
        let isSwitchOn = switchState.isOn
        
        if isSwitchOn {
            currentInstallation?.addUniqueObject(self.parseChannel, forKey: "channels")
        } else {
            currentInstallation?.remove(self.parseChannel, forKey: "channels")
        }
        
        self.alertCell.configureLoading()
        
        currentInstallation?.saveInBackground { [weak self] (succeeded, error)  in
            guard let `self` = self else {
                // self might be nil if we've popped the view controller when the completion block is called
                return
            }
            
            guard error == nil else {
                self.alertCell.configureLoadedWithSwitchOn(!isSwitchOn)
                print("Error subscribing to services: \(error!)")
                return
            }
            
            let subscribed = succeeded && isSwitchOn
            self.alertCell.configureLoadedWithSwitchOn(subscribed)
            
            if subscribed {
                self.addServiceIdToSubscribedList()
            }
            else {
                self.removeServiceIdFromSubscribedList()
            }
        }
    }
    
    // MARK: - refresh
    func refresh() {
        self.fetchLatestWeatherData()
        self.fetchLatestDisruptionData()
    }
    
    // MARK: - Datasource generation
    fileprivate func generateDatasource() {
        var sections = [Section]()
        
        //disruption section
        let disruptionRow: Row
        var footer: String?
        
        if self.refreshingDisruptionInfo {
            disruptionRow = Row.loading
        }
        else if self.disruptionDetails == nil {
            disruptionRow = Row.textOnly(text: "Unable to fetch the disruption status for this service.")
        }
        else {
            if let disruptionStatus = self.disruptionDetails?.disruptionStatus {
                switch disruptionStatus {
                case .normal:
                    if self.disruptionDetails!.hasAdditionalInfo {
                        disruptionRow = Row.noDisruption(disruptionDetails: disruptionDetails!, viewControllerGenerator: { [unowned self] in
                                return self.webInfoViewController("Additional info", content: self.disruptionDetails!.additionalInfo!)
                            })
                    }
                    else {
                        disruptionRow = Row.noDisruption(disruptionDetails: disruptionDetails!, viewControllerGenerator: { return nil })
                    }
                case .sailingsAffected, .sailingsCancelled:
                    if let disruptionInfo = disruptionDetails {
                        footer = disruptionInfo.lastUpdated
                        
                        disruptionRow = Row.disruption(disruptionDetails: disruptionInfo, viewControllerGenerator: { [unowned self] in
                            
                            var disruptionInformation = disruptionInfo.details ?? ""
                            if self.disruptionDetails!.hasAdditionalInfo {
                                disruptionInformation += "</p>"
                                disruptionInformation += self.disruptionDetails!.additionalInfo!
                            }
                            
                            return self.webInfoViewController("Disruption information", content:disruptionInformation)
                            })
                    }
                    else {
                        disruptionRow = Row.textOnly(text: "Unable to fetch the disruption status for this service.")
                    }
                case .unknown:
                    disruptionRow = Row.textOnly(text: "Unable to fetch the disruption status for this service.")
                }
            }
            else {
                // no disruptionStatus
                disruptionRow = Row.noDisruption(disruptionDetails: nil, viewControllerGenerator: { return nil })
            }
        }
        
        let disruptionSection: Section
        switch viewConfiguration {
        case .full:
            disruptionSection = Section(title: nil, footer: footer, rows: [disruptionRow, Row.alert])
        case .previewing:
            disruptionSection = Section(title: nil, footer: footer, rows: [disruptionRow])
        }
        sections.append(disruptionSection)
        
        if viewConfiguration == .full {
            var timetableRows = [Row]()
            
            if let serviceId = serviceStatus.serviceId, Departures.arePortAvailable(serviceId: serviceId) {
                let departuresRow: Row = Row.basic(title: "Departures", subtitle: nil,  viewControllerGenerator: { [unowned self] in
                    return self.departuresViewController(serviceId: serviceId)
                })
                timetableRows.append(departuresRow)
            }
            
            // winter timetable
            if isWinterTimetableAvailable() {
                let winterTimetableRow: Row = Row.basic(title: "Winter timetable", subtitle: nil, viewControllerGenerator: { [unowned self] in
                    return self.pdfTimeTableViewController(self.winterPath(), title: "Winter timetable")
                    })
                timetableRows.append(winterTimetableRow)
            }
            
            // summer timetable
            if isSummerTimetableAvailable() {
                let summerTimetableRow: Row = Row.basic(title: "Summer timetable", subtitle: nil, viewControllerGenerator: { [unowned self] in
                    self.pdfTimeTableViewController(self.summerPath(), title: "Summer timetable")
                    })
                timetableRows.append(summerTimetableRow)
            }
            
            if timetableRows.count > 0 {
                let timetableSection = Section(title: "Timetables", footer: nil, rows: timetableRows)
                sections.append(timetableSection)
            }
        }
        
        // weather sections
        if let locations = self.locations {
            for location in locations {
                var weatherRows = [Row]()
                
                switch (location.latitude, location.longitude) {
                case (.some(_), .some(_)):
                    let weatherRow = Row.weather(location: location)
                    weatherRows.append(weatherRow)
                    sections.append(Section(title: location.name, footer: nil, rows: weatherRows))
                default:
                    break
                }
            }
        }
        
        self.dataSource = sections
    }
    
    // MARK: - Utility methods
    @objc func animateWindVanes() {
        for cell in self.tableView.visibleCells {
            if let weatherCell = cell as? ServiceDetailWeatherCell {
                let randomDelay = Double(arc4random_uniform(4))
                delay(randomDelay) {
                    weatherCell.tryAnimateWindArrow()
                }
            }
        }
    }
    
    fileprivate func initializeTable() {
        self.generateDatasource()
        self.tableView.reloadData()
        
        var backgroundViewFrame = self.viewBackground.frame
        backgroundViewFrame.size.height = self.tableView.contentSize.height + (UIScreen.main.bounds.size.height)
        self.viewBackground.frame = backgroundViewFrame
    }
    
    fileprivate func fetchLatestDisruptionData() {
        let reloadServiceInfo: () -> () = {
            self.refreshingDisruptionInfo = false
            self.generateDatasource()
            
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
        
        if let serviceId = self.serviceStatus.serviceId {
            ServicesAPIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, _ in
                self.disruptionDetails = disruptionDetails
                reloadServiceInfo()
            }
        }
        else {
            reloadServiceInfo()
        }
    }
    
    fileprivate func fetchLatestWeatherData() {
        guard let locations = self.locations else { return }

        for location in locations {
            WeatherAPIClient.sharedInstance.fetchWeatherForLocation(location) { [weak self] weather, error in
                if self == nil {
                    return
                }
                
                if let error = error {
                    NSLog("Error loading weather: \(error)")
                }
                
                location.weather = weather
                location.weatherFetchError = error
                
                self!.reloadWeatherForLocation(location)
            }
        }
    }
    
    fileprivate func reloadWeatherForLocation(_ location: Location) {
        if let indexPath = self.indexPathForLocation(location) {
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    fileprivate func indexPathForLocation(_ location: Location) -> IndexPath? {
        var sectionCount = 0
        
        for section in self.dataSource {
            
            var rowCount = 0
            for row in section.rows {
                switch row {
                case let .weather(rowLocation):
                    if location == rowLocation {
                        return IndexPath(row: rowCount, section: sectionCount)
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
    
    fileprivate func isWinterTimetableAvailable() -> Bool {
        if serviceStatus.serviceId == nil {
            return false
        }
        
        return FileManager.default.fileExists(atPath: winterPath())
    }
    
    fileprivate func isSummerTimetableAvailable() -> Bool {
        if serviceStatus.serviceId == nil {
            return false
        }
        
        return FileManager.default.fileExists(atPath: summerPath())
    }

    fileprivate func winterPath() -> String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2017/Winter/\(serviceStatus.serviceId!).pdf")
    }
    
    fileprivate func summerPath() -> String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2018/Summer/\(serviceStatus.serviceId!).pdf")
    }
    
    fileprivate func pdfTimeTableViewController(_ path: String, title: String) -> UIViewController {
        let previewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TimetablePreview") as! TimetablePreviewViewController
        previewViewController.serviceStatus = self.serviceStatus
        previewViewController.url = URL(string: path)
        previewViewController.title = title
        
        return previewViewController
    }
    
    fileprivate func mapViewController() -> UIViewController {
        let mapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
        
        if let actualRoute = self.serviceStatus.route {
            mapViewController.title = actualRoute
        }
        else {
            mapViewController.title = "Map"
        }
        
        mapViewController.locations = self.locations
        
        return mapViewController
    }
    
    fileprivate func departuresViewController(serviceId: Int) -> UIViewController? {
        let timetableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "timetableViewController") as! TimetableViewController
        timetableViewController.serviceId = serviceId
        return timetableViewController
    }
    
    fileprivate func webInfoViewController(_ title: String, content: String) -> UIViewController {
        let disruptionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebInformation") as! WebInformationViewController
        disruptionViewController.title = title
        disruptionViewController.html = content
        return disruptionViewController
    }
    
    fileprivate func setMapVisibleRect() {
        guard let mapViewDelegate = mapViewDelegate else { return }
        
        let rect = calculateMapRectForAnnotations(mapViewDelegate.portAnnotations)
        
        // 40 padding from top to show annotation otherwise we just see the bottom of the annoation
        let topInset = CGFloat(40) + MainStoryBoard.Constants.motionEffectAmount
        
        // 5 padding so the bottom of the annoation is padded from the top of the header
        var bottomInset = view.bounds.size.height - MainStoryBoard.Constants.contentInset + 5
        if #available(iOS 11.0, *) {
            bottomInset = bottomInset - view.safeAreaInsets.bottom
        }
        
        let visibleRect = mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsetsMake(topInset, 30, bottomInset, 30))
        
        mapView.setVisibleMapRect(visibleRect, animated: false)
    }
    
    fileprivate func addServiceIdToSubscribedList() {
        guard let serviceId = self.serviceStatus.serviceId else {
            return
        }
        
        var currentServiceIds = UserDefaults.standard.array(forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
        
        if let existingServiceId = currentServiceIds.filter({ $0 == serviceId }).first {
            currentServiceIds.remove(at: currentServiceIds.index(of: existingServiceId)!)
            currentServiceIds.append(existingServiceId)
        }
        else {
            currentServiceIds.insert(serviceId, at: 0)
        }
        
        UserDefaults.standard.setValue(currentServiceIds, forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey)
        UserDefaults.standard.synchronize()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.sendWatchAppContext()
    }
    
    fileprivate func removeServiceIdFromSubscribedList() {
        guard let serviceId = self.serviceStatus.serviceId else {
            return
        }
        
        var currentServiceIds = UserDefaults.standard.array(forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey) as? [Int] ?? [Int]()
        
        if let existingServiceId = currentServiceIds.filter({ $0 == serviceId }).first {
            currentServiceIds.remove(at: currentServiceIds.index(of: existingServiceId)!)
        }
        
        UserDefaults.standard.setValue(currentServiceIds, forKey: ServicesViewController.subscribedServiceIdsUserDefaultsKey)
        UserDefaults.standard.synchronize()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.sendWatchAppContext()
    }
}

extension ServiceDetailTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return dataSource[section].footer
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case let .basic(title, subtitle, viewControllerGenerator):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.basicCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel!.text = title
            
            if let subtitle = subtitle {
                cell.detailTextLabel!.text = subtitle
            }
            else {
                cell.detailTextLabel!.text = ""
            }
            
            let shouldHideDisclosure = viewControllerGenerator() == nil || viewConfiguration == .previewing
            cell.accessoryType = shouldHideDisclosure ? .none : .disclosureIndicator
            
            return cell
        case let .disruption(disruptionDetails, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.disruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailDisruptionsTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            return cell
        case let .noDisruption(disruptionDetails, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailNoDisruptionTableViewCell
            cell.configureWithDisruptionDetails(disruptionDetails)
            
            if viewConfiguration == .previewing {
                cell.hideInfoButton()
            }
            
            return cell
        case .loading:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.loadingCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailLoadingTableViewCell
            cell.activityIndicatorView.startAnimating()
            return cell
        case let .textOnly(text):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.textOnlyCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailTextOnlyCell
            cell.labelText.text = text
            return cell
        case let .weather(location):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.weatherCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailWeatherCell
            cell.selectionStyle = .none
            cell.configureWithLocation(location, animate: true)
            cell.delegate = self
            return cell
        case .alert:
            return self.alertCell
        }
    }
}

extension ServiceDetailTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case .basic:
            return 44.0
        case let .disruption(disruptionDetails, _):
            let height = ServiceDetailDisruptionsTableViewCell.heightWithDisruptionDetails(disruptionDetails, tableView: tableView)
            return height
        case let .noDisruption(disruptionDetails, _):
            let height = ServiceDetailNoDisruptionTableViewCell.heightWithDisruptionDetails(disruptionDetails, tableView: tableView)
            return height
        case .loading:
            return 55.0
        case let .textOnly(text):
            let height = ServiceDetailTextOnlyCell.heightWithText(text, tableView: tableView)
            return height
        case let .weather(location):
            let height = ServiceDetailWeatherCell.heightWithLocation(location, tableView: tableView)
            return height
        case .alert:
            return 44.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        let viewController: UIViewController?
        
        switch row {
        case .basic(_, _, let viewControllerGenerator):
            viewController = viewControllerGenerator()
        case .disruption(_, let viewControllerGenerator):
            viewController = viewControllerGenerator()
        case .noDisruption(_, let viewControllerGenerator):
            viewController = viewControllerGenerator()
        default:
            viewController = nil;
        }
        
        if let viewController = viewController {
            show(viewController, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case .weather(_):
            if let weatherCell = cell as? ServiceDetailWeatherCell {
                weatherCell.viewSeparator.backgroundColor = tableView.separatorColor
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.tealTextColor()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource[section].showHeader {
            return UITableViewAutomaticDimension
        }
        else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if dataSource[section].showFooter {
            return UITableViewAutomaticDimension
        }
        else {
            return CGFloat.leastNormalMagnitude
        }
    }
}

extension ServiceDetailTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case .basic(_, _, let viewControllerGenerator):
            return viewControllerGenerator()
        case .disruption(_, let viewControllerGenerator):
            return viewControllerGenerator()
        case .noDisruption(_, let viewControllerGenerator):
            return viewControllerGenerator()
        default:
            return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}

extension ServiceDetailTableViewController: ServiceDetailWeatherCellDelegate{
    func didTouchReloadForWeatherCell(_ cell: ServiceDetailWeatherCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case let .weather(location):
            WeatherAPIClient.sharedInstance.fetchWeatherForLocation(location) { [weak self] weather, error in
                if self == nil {
                    return
                }
                
                if let error = error {
                    NSLog("Error loading weather: \(error)")
                }
                
                location.weather = weather
                location.weatherFetchError = error
                
                self!.reloadWeatherForLocation(location)
            }
        default:
            break
        }
    }
}
