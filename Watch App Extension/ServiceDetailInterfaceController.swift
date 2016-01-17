//
//  InterfaceController.swift
//  Watch App Extension
//
//  Created by Stefan Church on 7/12/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation

class ServiceDetailInterfaceController: WKInterfaceController {
    
    static let cacheTimeoutSeconds = 600.0 // 10 minutes
    static let connectionErrorMessage = "There was problem with the connection. Force touch the screen to refresh."
    
    @IBOutlet var labelArea: WKInterfaceLabel!
    @IBOutlet var labelDisruptionInformation: WKInterfaceLabel!
    @IBOutlet var labelRoute: WKInterfaceLabel!
    @IBOutlet var labelStatus: WKInterfaceLabel!
    @IBOutlet var map: WKInterfaceMap!
    @IBOutlet var imageStatus: WKInterfaceImage!
    
    var dataTask: NSURLSessionDataTask?
    var lastFetchTime: NSDate?
    var service: Service?

    // MARK: - View lifecycle
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let service = context as? Service {
            self.service = service
            
            if service.isDefault {
                super.becomeCurrentPage()
                service.isDefault = false
            }
            
            self.configureView()
        }
    }

    override func willActivate() {
        super.willActivate()
        
        fetchDisruptionDetails()
    }
    
    override func didAppear() {
        super.didAppear()
        
        // When paging through controllers if the user hit refresh before the controller was ready the app would hang forever
        // so we only add the menu item once the controllelr had appeared
        addMenuItemWithItemIcon(.Repeat, title: "Refresh", action: Selector("refresh"))
        
        if let service = self.service {
            self.updateUserActivity("com.stefanchurch.ferryservices.viewservice", userInfo: ["serviceId": service.serviceId], webpageURL: nil)
        }
    }
    
    override func willDisappear() {
        super.willDisappear()
        
        clearAllMenuItems()
    }
    
    // MARK: - View configuration
    private func configureLoadingView() {
        if let service = self.service {
            self.labelRoute.setText(service.route)
        }
        
        self.labelStatus.setText("LOADING...")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImageNamed("grey")
    }
    
    private func configureErrorViewWithMessage(message: String) {
        self.labelRoute.setText(message)
        self.labelStatus.setText("")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImage(nil)
    }
    
    private func configureView() {
        guard let service = self.service else {
            return
        }
        
        self.labelArea.setText(service.area)
        
        self.labelRoute.setText(service.route)
        
        if let disruptionDetailsHtml = service.disruptionDetails {
            if let data = disruptionDetailsHtml.dataUsingEncoding(NSUTF8StringEncoding) {
                do {
                    let attributeText = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
                    self.labelDisruptionInformation.setAttributedText(attributeText)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
        
        switch service.status {
        case .Normal:
            self.labelStatus.setText("NO DISRUPTIONS")
            self.imageStatus.setImageNamed("green")
        case .SailingsAffected:
            self.labelStatus.setText("DISRUPTED")
            self.imageStatus.setImageNamed("amber")
        case .SailingsCancelled:
            self.labelStatus.setText("CANCELLED")
            self.imageStatus.setImageNamed("red")
        case .Unknown:
            self.labelStatus.setText("UNKNOWN")
            self.imageStatus.setImageNamed("grey")
        }
        
        if let ports = service.ports {
            configureMapWithPorts(ports)
        }
    }
    
    private func configureMapWithPorts(ports: [Port]) {
        var coordinates = [CLLocationCoordinate2D]()
        
        for port in ports {
            let location = CLLocationCoordinate2D(latitude: port.latitude, longitude: port.longitude)
            coordinates.append(location)
            self.map.addAnnotation(location, withPinColor: .Red)
        }
        
        let mapRectForCoords = calculateMapRectForCoordinates(coordinates)
        
        var region = MKCoordinateRegionForMapRect(mapRectForCoords)
        region.span.latitudeDelta = 1.4
        region.span.longitudeDelta = 1.4
        
        region.center = CLLocationCoordinate2D(latitude: region.center.latitude + 0.24, longitude: region.center.longitude)
        
        self.map.setRegion(region)
    }
    
    // MARK: - UI Actions
    @IBAction func refresh() {
        lastFetchTime = nil
        fetchDisruptionDetails()
    }
    
    // MARK: - Fetch
    private func fetchDisruptionDetails() {
        guard let service = self.service else {
            return
        }
        
        guard self.dataTask?.state != .Running else {
            return
        }
        
        if let lastFetchTime = self.lastFetchTime {
            let secondsSinceLastFetch = NSDate().timeIntervalSinceDate(lastFetchTime)
            guard secondsSinceLastFetch > ServiceDetailInterfaceController.cacheTimeoutSeconds else {
                self.configureView()
                return
            }
        }
        
        self.configureLoadingView()
        
        let semaphore = dispatch_semaphore_create(0)
        
        let url = NSURL(string: "http://stefanchurch.com:4567/services/\(service.serviceId)")!
        
        NSProcessInfo().performExpiringActivityWithReason("Download ferry service details") { expired in
            guard !expired else {
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * Double(NSEC_PER_SEC)))
            dispatch_semaphore_wait(semaphore, timeout)
        }
        
        dataTask = NSURLSession.sharedSession().dataTaskWithURL(url) { [weak self] data, response, error in
            defer {
                dispatch_semaphore_signal(semaphore)
            }
            
            guard self != nil else {
                return
            }
            
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue(), {
                    self?.configureErrorViewWithMessage(ServiceDetailInterfaceController.connectionErrorMessage)
                    self?.lastFetchTime = nil
                })
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject] {
                    dispatch_async(dispatch_get_main_queue(), {
                        if let service = Service(json: jsonDictionary) {
                            self?.service =  service
                            self?.configureView()
                            self?.lastFetchTime = NSDate()
                        }
                        else {
                            self?.configureErrorViewWithMessage("There was a problem with the server response.")
                            self?.lastFetchTime = nil
                        }
                    })
                }
                
            } catch let error as NSError {
                print("Error parsing json: \(error.localizedDescription)")
                dispatch_async(dispatch_get_main_queue(), {
                    self?.configureErrorViewWithMessage("There was a problem with the server response.")
                    self?.lastFetchTime = nil
                })
            }
        }
        
        dataTask?.resume()
    }

    // MARK: -
    private func calculateMapRectForCoordinates(coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        return coordinates.reduce(MKMapRectNull) { rect, coordinate in
            let point = MKMapPointForCoordinate(coordinate)
            return MKMapRectUnion(rect, MKMapRect(origin: point, size: MKMapSize(width: 0.0, height: 0.0)))
        }
    }
}
