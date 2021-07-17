//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailViewController: UIViewController {
    
    class Section {
        var title: String?
        var footer: String?
        var rows: [Row]
        
        init (title: String?, footer: String?, rows: [Row]) {
            self.title = title
            self.footer = footer
            self.rows = rows
        }
    }
    
    enum Row {
        case winterTimetable
        case summerTimetable
        case disruption
        case noDisruption
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
    
    var alertCell: AlertCell = UINib(nibName: "AlertCell", bundle: nil).instantiate(withOwner: nil, options: nil).first as! AlertCell
    
    var serviceID: Int!
    var service: Service?

    var mapViewDelegate: ServiceMapDelegate?
    var dataSource: [Section] = []
    var headerHeight: CGFloat?
    var mapMotionEffect: UIMotionEffectGroup!
    var mapRectSet = false
    var refreshingDisruptionInfo: Bool = true // show table as refreshing initially
    var viewBackground: UIView!
    var windAnimationTimer: Timer!
    var weather: [LocationWeather?] = []
        
    // MARK: -
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        NotificationCenter.default.addObserver(self, selector: #selector(ServiceDetailViewController.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if let service = service {
            LastViewedServices.register(service)
        }
        
        tableView.contentInset = UIEdgeInsets.init(top: MainStoryBoard.Constants.contentInset, left: 0, bottom: 0, right: 0)
        
        alertCell.switchAlert.addTarget(self, action: #selector(ServiceDetailViewController.alertSwitchChanged(_:)), for: UIControl.Event.valueChanged)
        alertCell.configureLoading()
        
        APIClient.getInstallationServices(installationID: Installation.id) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .failure:
                self.alertCell.configureLoadedWithSwitchOn(false)
                self.removeServiceIdFromSubscribedList()
                
            case .success(let subscribedServices):
                guard let service = self.service else { return }
                
                let subscribed = subscribedServices.map { $0.serviceId }.contains(service.serviceId)
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
        
        mapMotionEffect = UIMotionEffectGroup()
        mapMotionEffect.motionEffects = [horizontalMotionEffect, vertiacalMotionEffect]
        mapView.addMotionEffect(mapMotionEffect)
        
        // extend edges of map as motion effect will move them
        constraintMapViewLeading.constant = -MainStoryBoard.Constants.motionEffectAmount
        constraintMapViewTrailing.constant = -MainStoryBoard.Constants.motionEffectAmount
        constraintMapViewTop.constant = -MainStoryBoard.Constants.motionEffectAmount
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchedButtonShowMap(_:)))
        tableView.backgroundView = UIView()
        tableView.backgroundView?.addGestureRecognizer(tap)
        tableView.backgroundColor = UIColor.clear
        
        tableView.register(UINib(nibName: "DisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.disruptionsCell)
        tableView.register(UINib(nibName: "NoDisruptionsCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell)
        tableView.register(UINib(nibName: "TextOnlyCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.textOnlyCell)
        tableView.register(UINib(nibName: "WeatherCell", bundle: nil), forCellReuseIdentifier: MainStoryBoard.TableViewCellIdentifiers.weatherCell)
        
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.estimatedRowHeight = 44.0;
        
        configureView()
        
        let backgroundViewFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: tableView.contentSize.height + (UIScreen.main.bounds.size.height))
        viewBackground = UIView(frame: backgroundViewFrame)
        viewBackground.backgroundColor = UIColor(named: "Background")
        view.insertSubview(viewBackground, belowSubview: tableView)
                
        fetchLatestDisruptionData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // clip bounds so map doesn't expand over the edges when we animated to/from view
        view.clipsToBounds = true
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        windAnimationTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ServiceDetailViewController.animateWindVanes), userInfo: nil, repeats: true)
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
        view.clipsToBounds = true
        
        windAnimationTimer.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if headerHeight == nil {
            configureHeader()
        }
        
        if !mapRectSet {
            // Need to do this at this point as we need to know the size of the view to calculate the rect that is shown
            setMapVisibleRect()
            mapRectSet = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            headerHeight = nil
            view.setNeedsLayout()
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
        fetchLatestDisruptionData()
    }
    
    private func configureView() {
        title = service?.area
        
        labelArea.text = service?.area
        labelRoute.text = service?.route
        
        weather = service?.locations.map { _ in nil } ?? []
        
        mapViewDelegate = ServiceMapDelegate(mapView: mapView, locations: service?.locations ?? [])
        mapViewDelegate?.shouldAllowAnnotationSelection = false
        mapView.delegate = mapViewDelegate
        
        generateDatasource()
        tableView.reloadData()
        
        mapRectSet = false
        headerHeight = nil
        view.setNeedsLayout()
    }
    
    // MARK: - ui actions
    @IBAction func touchedButtonShowMap(_ sender: UIButton) {
        let mapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
        mapViewController.title = service?.route
        mapViewController.locations = service?.locations
        
        show(mapViewController, sender: self)
    }
    
    @objc private func alertSwitchChanged(_ switchState: UISwitch) {
        alertCell.configureLoading()
        if switchState.isOn {
            subscribeToService()
        } else {
            unsubscribeFromService()
        }
    }
    
    private func configureHeader() {
        labelArea.preferredMaxLayoutWidth = view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
        labelRoute.preferredMaxLayoutWidth = view.bounds.size.width - (MainStoryBoard.Constants.headerMargin * 2)
        
        tableView.tableHeaderView?.setNeedsLayout()
        tableView.tableHeaderView?.layoutIfNeeded()
        let headerHeight = tableView.tableHeaderView?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: headerHeight)
        
        var frame = viewBackground.frame
        frame.origin.y = -tableView.contentOffset.y + headerHeight
        viewBackground.frame = frame
        
        self.headerHeight = headerHeight
        
        tableView.reloadData()
    }
    
    private func subscribeToService() {
        guard let service = service else { return }
        
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
        guard let service = service else { return }
        
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
    
    // MARK: - Datasource generation
    private func generateDatasource() {
        guard let service = service else {
            dataSource = [Section(title: nil, footer: nil, rows: [.loading])]
            return
        }
        
        var sections = [Section]()
        
        let disruptionRow: Row = {
            if refreshingDisruptionInfo {
                return Row.loading
            } else {
                switch service.status {
                case .normal:
                    return Row.noDisruption
                case .disrupted, .cancelled:
                    return Row.disruption
                case .unknown:
                    return Row.textOnly(text: "Unable to fetch the disruption status for this service.")
                }
            }
        }()
        
        sections.append(
            Section(
                title: nil,
                footer: [.disrupted, .cancelled].contains(service.status) ? service.lastUpdated : nil,
                rows: UserDefaults.standard.bool(forKey: UserDefaultsKeys.registeredForNotifications)
                    ? [disruptionRow, Row.alert]
                    : [disruptionRow]
            )
        )
        
        let timetableRows = [
            FileManager.default.fileExists(atPath: service.winterPath) ? Row.winterTimetable : nil,
            FileManager.default.fileExists(atPath: service.summerPath) ? Row.summerTimetable : nil
        ].compactMap({$0})

        if timetableRows.count > 0 {
            let timetableSection = Section(title: "Timetables", footer: nil, rows: timetableRows)
            sections.append(timetableSection)
        }
        
        // weather sections
        for (index, location) in service.locations.enumerated() {
            sections.append(Section(title: location.name, footer: nil, rows: [.weather(index: index)]))
        }
        
        dataSource = sections
    }
    
    // MARK: - Utility methods
    @objc private func animateWindVanes() {
        for cell in tableView.visibleCells {
            guard let weatherCell = cell as? WeatherCell else { continue }
            let randomDelay = Double(arc4random_uniform(4))
            delay(randomDelay) {
                weatherCell.tryAnimateWindArrow()
            }
        }
    }
    
    private func fetchLatestDisruptionData() {
        APIClient.fetchService(serviceID: serviceID) { [weak self] result in
            guard case let .success(service) = result else { return }
            guard let self = self else { return }
            self.service = service
            self.refreshingDisruptionInfo = false
            self.configureView()
            self.fetchLatestWeatherData()
        }
    }
    
    private func fetchLatestWeatherData() {
        guard let service = service else { return }
        for (index, location) in service.locations.enumerated() {
            WeatherAPIClient.sharedInstance.fetchWeatherForLocation(location) { [weak self] result in
                guard let self = self else { return }
                guard case .success(let weather) = result else { return }
                
                self.weather[index] = weather
                self.generateDatasource()
                self.tableView.reloadData()
            }
        }
    }
    
    private func pdfTimeTableViewController(_ path: String, title: String) -> UIViewController {
        let previewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TimetablePreview") as! TimetablePreviewViewController
        previewViewController.service = service
        previewViewController.url = URL(fileURLWithPath: path)
        previewViewController.title = title
        
        return previewViewController
    }
    
    private func webInfoViewController(_ title: String, content: String) -> UIViewController {
        let disruptionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebInformation") as! WebInformationViewController
        disruptionViewController.title = title
        disruptionViewController.html = content
        return disruptionViewController
    }
    
    private func setMapVisibleRect() {
        guard let mapViewDelegate = mapViewDelegate else { return }
        
        let rect = calculateMapRectForAnnotations(mapViewDelegate.portAnnotations)
        
        let bottomInset = view.bounds.size.height - MainStoryBoard.Constants.contentInset - view.safeAreaInsets.bottom - (navigationController?.navigationBar.bounds.height ?? 44) - UIApplication.shared.statusBarFrame.height
        
        let visibleRect = mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets.init(top: 60, left: 30, bottom: bottomInset + 5, right: 30))
        
        mapView.setVisibleMapRect(visibleRect, animated: false)
    }
    
    private func addServiceIdToSubscribedList() {
        guard let service = service else { return }
        
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
    
    private func removeServiceIdFromSubscribedList() {
        guard let service = service else { return }
        
        var currentServiceIds = UserDefaults.standard.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? [Int]()
        
        if let existingServiceId = currentServiceIds.filter({ $0 == service.serviceId }).first {
            currentServiceIds.remove(at: currentServiceIds.firstIndex(of: existingServiceId)!)
        }
        
        UserDefaults.standard.setValue(currentServiceIds, forKey: UserDefaultsKeys.subscribedService)
        UserDefaults.standard.synchronize()
    }
}

extension ServiceDetailViewController: UITableViewDataSource {
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
        case .winterTimetable:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.basicCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel?.text = "Winter 2020–2021"
            cell.accessoryType = .disclosureIndicator
            return cell
        
        case .summerTimetable:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.basicCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel?.text = "Summer 2021"
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .disruption:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.disruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! DisruptionsCell
            cell.configureWithService(service)
            return cell
            
        case .noDisruption:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.noDisruptionsCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NoDisruptionCell
            cell.configureWithService(service)
            return cell
            
        case .loading:
            let identifier = MainStoryBoard.TableViewCellIdentifiers.loadingCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! LoadingCell
            cell.activityIndicatorView.startAnimating()
            return cell
            
        case let .textOnly(text):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.textOnlyCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! TextCell
            cell.labelText.text = text
            return cell
            
        case .weather(let index):
            let identifier = MainStoryBoard.TableViewCellIdentifiers.weatherCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! WeatherCell
            cell.selectionStyle = .none
            
            if index < weather.count {
                cell.configure(with: weather[index], animate: true)
            } else {
                cell.configure(with: nil, animate: true)
            }
            
            return cell
            
        case .alert:
            return alertCell
            
        }
    }
}

extension ServiceDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let service = service else { return }
        
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case .summerTimetable:
            show(pdfTimeTableViewController(service.summerPath, title: "Summer timetable"), sender: self)
        case .winterTimetable:
            show(pdfTimeTableViewController(service.winterPath, title: "Winter timetable"), sender: self)
        case .disruption:
            if let additionalInfo = service.additionalInfo {
                show(webInfoViewController("Disruption information", content:additionalInfo), sender: self)
            }
        case .noDisruption:
            if let additionalInfo = service.additionalInfo {
                show(webInfoViewController("Additional info", content:additionalInfo), sender: self)
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = dataSource[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
        
        switch row {
        case .weather:
            if let weatherCell = cell as? WeatherCell {
                weatherCell.viewSeparator.backgroundColor = tableView.separatorColor
            }
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor(named: "Text")
    }
}

private extension Service {
    var lastUpdated: String? {
        return lastUpdatedDate.map { "Last updated \($0.relativeTimeSinceNowText())" }
    }
    
    var winterPath: String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2020/Winter/\(serviceId).pdf")
    }
    
    var summerPath: String {
        return (Bundle.main.bundlePath as NSString).appendingPathComponent("Timetables/2021/Summer/\(serviceId).pdf")
    }
}
