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

typealias ViewControllerGenerator = () -> UIViewController?

class ServiceDetailTableViewController: UIViewController {
    
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
        case disruption(service: Service, viewControllerGenerator: ViewControllerGenerator)
        case noDisruption(service: Service, viewControllerGenerator: ViewControllerGenerator)
        case loading
        case textOnly(text: String)
        case weather(index: Int)
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
    
    let isRegisteredForNotifications = UserDefaults.standard.bool(forKey: UserDefaultsKeys.registeredForNotifications)
    var mapViewDelegate: ServiceMapDelegate?
    var dataSource: [Section] = []
    var headerHeight: CGFloat?
    var mapMotionEffect: UIMotionEffectGroup!
    var mapRectSet = false
    var refreshingDisruptionInfo: Bool = true // show table as refreshing initially
    var service: Service!
    var viewBackground: UIView!
    var windAnimationTimer: Timer!
    var weather: [LocationWeather?]!
        
    // MARK: -
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.service.area
        
        navigationItem.largeTitleDisplayMode = .never
        
        weather = service.locations.map { _ in nil }
        
        self.labelArea.text = self.service.area
        self.labelRoute.text = self.service.route
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServiceDetailTableViewController.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        LastViewedServices.register(service)
        
        // configure tableview
        self.tableView.contentInset = UIEdgeInsets.init(top: MainStoryBoard.Constants.contentInset, left: 0, bottom: 0, right: 0)
        
        // alert cell
        self.alertCell.switchAlert.addTarget(self, action: #selector(ServiceDetailTableViewController.alertSwitchChanged(_:)), for: UIControl.Event.valueChanged)
        self.alertCell.configureLoading()
        
        APIClient.getInstallationServices(installationID: Installation.id) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .failure:
                self.alertCell.configureLoadedWithSwitchOn(false)
                self.removeServiceIdFromSubscribedList()
                
            case .success(let subscribedServices):
                let subscribed = subscribedServices.map { $0.serviceId }.contains(self.service.serviceId)
                self.alertCell.configureLoadedWithSwitchOn(subscribed)
                
                if subscribed {
                    self.addServiceIdToSubscribedList()
                }
                else {
                    self.removeServiceIdFromSubscribedList()
                }
            }
        }
        
        // map motion effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffect.EffectType.tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
        horizontalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
        
        let vertiacalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffect.EffectType.tiltAlongVerticalAxis)
        vertiacalMotionEffect.minimumRelativeValue = -MainStoryBoard.Constants.motionEffectAmount
        vertiacalMotionEffect.maximumRelativeValue = MainStoryBoard.Constants.motionEffectAmount
        
        self.mapMotionEffect = UIMotionEffectGroup()
        self.mapMotionEffect.motionEffects = [horizontalMotionEffect, vertiacalMotionEffect]
        self.mapView.addMotionEffect(self.mapMotionEffect)
        
        // extend edges of map as motion effect will move them
        self.constraintMapViewLeading.constant = -MainStoryBoard.Constants.motionEffectAmount
        self.constraintMapViewTrailing.constant = -MainStoryBoard.Constants.motionEffectAmount
        self.constraintMapViewTop.constant = -MainStoryBoard.Constants.motionEffectAmount
        
        mapViewDelegate = ServiceMapDelegate(mapView: mapView, locations: service.locations)
        mapViewDelegate?.shouldAllowAnnotationSelection = false
        mapView.delegate = mapViewDelegate
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchedButtonShowMap(_:)))
        self.tableView.backgroundView = UIView()
        self.tableView.backgroundView?.addGestureRecognizer(tap)
        
        let backgroundViewFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        viewBackground = UIView(frame: backgroundViewFrame)
        viewBackground.backgroundColor = UIColor(named: "Background")
        view.insertSubview(viewBackground, belowSubview: tableView)
        
        self.tableView.backgroundColor = UIColor.clear
        
        self.tableView.register(UINib(nibName: "DisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell)
        self.tableView.register(UINib(nibName: "NoDisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
        self.tableView.register(UINib(nibName: "TextOnlyCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell)
        self.tableView.register(UINib(nibName: "WeatherCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.weatherCell)
        
        self.initializeTable()
        self.refresh()
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
            let headerHeight = self.tableView.tableHeaderView!.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
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
        self.alertCell.configureLoading()
        if switchState.isOn {
            subscribeToService()
        } else {
            unsubscribeFromService()
        }
    }
    
    private func subscribeToService() {
        APIClient.addService(for: Installation.id, serviceID: service.serviceId) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .failure:
                self.alertCell.configureLoadedWithSwitchOn(false)
                let alert = UIAlertController(
                    title: "Error",
                    message: "A problem occured. Please try again later.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            case .success:
                self.alertCell.configureLoadedWithSwitchOn(true)
                self.addServiceIdToSubscribedList()
            }
        }
    }
    
    private func unsubscribeFromService() {
        APIClient.removeService(for: Installation.id, serviceID: service.serviceId) { [weak self]  result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .failure:
                self.alertCell.configureLoadedWithSwitchOn(true)
                let alert = UIAlertController(
                    title: "Error",
                    message: "A problem occured. Please try again later.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            case .success:
                self.alertCell.configureLoadedWithSwitchOn(false)
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
        
        if refreshingDisruptionInfo {
            disruptionRow = Row.loading
        } else {
            switch service.status {
            case .normal:
                if let additionalInfo = service.additionalInfo {
                    disruptionRow = Row.noDisruption(service: service, viewControllerGenerator: { [unowned self] in
                        return self.webInfoViewController("Additional info", content: additionalInfo)
                    })
                }
                else {
                    disruptionRow = Row.noDisruption(service: service, viewControllerGenerator: { return nil })
                }
            case .disrupted, .cancelled:
                footer = service.lastUpdated
                disruptionRow = Row.disruption(service: service, viewControllerGenerator: { [unowned self] in
                    if let additionalInfo = self.service.additionalInfo {
                        return self.webInfoViewController("Disruption information", content:additionalInfo)
                    } else {
                        return nil
                    }
                })
            case .unknown:
                disruptionRow = Row.textOnly(text: "Unable to fetch the disruption status for this service.")
            }
            
        }
        
        let disruptionRows = isRegisteredForNotifications ? [disruptionRow, Row.alert] : [disruptionRow]
        
        sections.append(Section(title: nil, footer: footer, rows: disruptionRows))
        
        var timetableRows = [Row]()

//        winter timetable
        if isWinterTimetableAvailable() {
            let winterTimetableRow: Row = Row.basic(title: "Winter 2020–2021", subtitle: nil, viewControllerGenerator: { [unowned self] in
                return self.pdfTimeTableViewController(self.winterPath(), title: "Winter timetable")
            })
            timetableRows.append(winterTimetableRow)
        }

//        summer timetable
        if isSummerTimetableAvailable() {
            let summerTimetableRow: Row = Row.basic(title: "Summer 2021", subtitle: nil, viewControllerGenerator: { [unowned self] in
                self.pdfTimeTableViewController(self.summerPath(), title: "Summer timetable")
            })
            timetableRows.append(summerTimetableRow)
        }

        if timetableRows.count > 0 {
            let timetableSection = Section(title: "Timetables", footer: nil, rows: timetableRows)
            sections.append(timetableSection)
        }
        
        // weather sections
        for (index, location) in service.locations.enumerated() {
            sections.append(Section(title: location.name, footer: nil, rows: [.weather(index: index)]))
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
        APIClient.fetchService(serviceID: service.serviceId) { result in
            guard case let .success(service) = result else { return }
            self.service = service
            self.refreshingDisruptionInfo = false
            self.generateDatasource()
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
    
    fileprivate func fetchLatestWeatherData() {
        for (index, location) in service.locations.enumerated() {
            WeatherAPIClient.sharedInstance.fetchWeatherForLocation(location) { [weak self] result in
                guard let self = self else { return }
                if case .success(let weather) = result {
                    self.weather[index] = weather
                }
                
                if let weatherSection = self.dataSource.firstIndex(where: {
                    if case Row.weather = $0.rows[0] {
                        return true
                    } else {
                        return false
                    }
                }) {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: weatherSection + index)], with: .none)
                }
            }
        }
    }
    
    fileprivate func isWinterTimetableAvailable() -> Bool {
        return FileManager.default.fileExists(atPath: winterPath())
    }
    
    fileprivate func isSummerTimetableAvailable() -> Bool {
        return FileManager.default.fileExists(atPath: summerPath())
    }
    
    fileprivate func winterPath() -> String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2020/Winter/\(service.serviceId).pdf")
    }
    
    fileprivate func summerPath() -> String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2021/Summer/\(service.serviceId).pdf")
    }
    
    fileprivate func pdfTimeTableViewController(_ path: String, title: String) -> UIViewController {
        let previewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TimetablePreview") as! TimetablePreviewViewController
        previewViewController.service = service
        previewViewController.url = URL(fileURLWithPath: path)
        previewViewController.title = title
        
        return previewViewController
    }
    
    fileprivate func mapViewController() -> UIViewController {
        let mapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
        mapViewController.title = service.route
        mapViewController.locations = service.locations
        
        return mapViewController
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
        
        let bottomInset = view.bounds.size.height - MainStoryBoard.Constants.contentInset - view.safeAreaInsets.bottom - navigationController!.navigationBar.bounds.height - UIApplication.shared.statusBarFrame.height
        
        let visibleRect = mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets.init(top: 60, left: 30, bottom: bottomInset + 5, right: 30))
        
        mapView.setVisibleMapRect(visibleRect, animated: false)
    }
    
    fileprivate func addServiceIdToSubscribedList() {
        var currentServiceIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? [Int]()
        
        if let existingServiceId = currentServiceIds.filter({ $0 == service.serviceId }).first {
            currentServiceIds.remove(at: currentServiceIds.firstIndex(of: existingServiceId)!)
            currentServiceIds.append(existingServiceId)
        }
        else {
            currentServiceIds.insert(service.serviceId, at: 0)
        }
        
        UserDefaults.standard.setValue(currentServiceIds, forKey: UserDefaultsKeys.subscribedService)
        UserDefaults.standard.synchronize()
    }
    
    fileprivate func removeServiceIdFromSubscribedList() {
        var currentServiceIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? [Int]()
        
        if let existingServiceId = currentServiceIds.filter({ $0 == service.serviceId }).first {
            currentServiceIds.remove(at: currentServiceIds.firstIndex(of: existingServiceId)!)
        }
        
        UserDefaults.standard.setValue(currentServiceIds, forKey: UserDefaultsKeys.subscribedService)
        UserDefaults.standard.synchronize()
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
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
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
            
            let shouldHideDisclosure = viewControllerGenerator() == nil
            cell.accessoryType = shouldHideDisclosure ? .none : .disclosureIndicator
            
            return cell
        case let .disruption(service, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.disruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailDisruptionsTableViewCell
            cell.configureWithService(service)
            return cell
        case let .noDisruption(service, _):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailNoDisruptionTableViewCell
            cell.configureWithService(service)
                        
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
        case .weather(let index):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.weatherCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ServiceDetailWeatherCell
            cell.selectionStyle = .none
            cell.configure(with: weather[index], animate: true)
            
            return cell
        case .alert:
            return self.alertCell
        }
    }
}

extension ServiceDetailTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = dataSource[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .basic:
            return 44.0
        case let .disruption(service, _):
            return ServiceDetailDisruptionsTableViewCell.heightWithService(service, tableView: tableView)
        case let .noDisruption(service, _):
            return ServiceDetailNoDisruptionTableViewCell.heightWithService(service, tableView: tableView)
        case .loading:
            return 55.0
        case let .textOnly(text):
            return ServiceDetailTextOnlyCell.heightWithText(text, tableView: tableView)
        case .weather(let index):
            return weather[index].map { ServiceDetailWeatherCell.height(for: $0, tableView: tableView) } ?? 0.0
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
        case .weather:
            if let weatherCell = cell as? ServiceDetailWeatherCell {
                weatherCell.viewSeparator.backgroundColor = tableView.separatorColor
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor(named: "Text")
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource[section].showHeader {
            return UITableView.automaticDimension
        }
        else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if dataSource[section].showFooter {
            return UITableView.automaticDimension
        }
        else {
            return CGFloat.leastNormalMagnitude
        }
    }
}

private extension Service {
    var lastUpdated: String? {
        return lastUpdatedDate.map { "Last updated \($0.relativeTimeSinceNowText())" }
    }
}
