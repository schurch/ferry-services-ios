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
    static let connectionErrorMessage = "There was problem with the connection. Please try again later."
    
    @IBOutlet var labelArea: WKInterfaceLabel!
    @IBOutlet var labelDisruptionInformation: WKInterfaceLabel!
    @IBOutlet var labelRoute: WKInterfaceLabel!
    @IBOutlet var labelStatus: WKInterfaceLabel!
    @IBOutlet var map: WKInterfaceMap!
    @IBOutlet var imageStatus: WKInterfaceImage!
    
    var dataTask: URLSessionDataTask?
    var lastFetchTime: Date?
    var service: Service?

    // MARK: - View lifecycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
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
        addMenuItem(with: .repeat, title: "Refresh", action: #selector(ServiceDetailInterfaceController.refresh))
        
        if let service = self.service {
            self.updateUserActivity("com.stefanchurch.ferryservices.viewservice", userInfo: ["serviceId": service.serviceId], webpageURL: nil)
        }
    }
    
    override func willDisappear() {
        super.willDisappear()
        
        clearAllMenuItems()
    }
    
    // MARK: - View configuration
    fileprivate func configureLoadingView() {
        if let service = self.service {
            self.labelRoute.setText(service.route)
        }
        
        self.labelStatus.setText("LOADING...")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImageNamed("grey")
    }
    
    fileprivate func configureErrorViewWithMessage(_ message: String) {
        self.labelRoute.setText(message)
        self.labelStatus.setText("")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImage(nil)
    }
    
    fileprivate func configureView() {
        guard let service = self.service else {
            return
        }
        
        self.labelArea.setText(service.area)
        
        self.labelRoute.setText(service.route)
        
        if let disruptionDetailsHtml = service.disruptionDetails {
            if let data = disruptionDetailsHtml.data(using: .utf8) {
                do {
                    let attributeText = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
                    self.labelDisruptionInformation.setAttributedText(attributeText)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
        
        switch service.status {
        case .normal:
            self.labelStatus.setText("NO DISRUPTIONS")
            self.imageStatus.setImageNamed("green")
        case .sailingsAffected:
            self.labelStatus.setText("DISRUPTED")
            self.imageStatus.setImageNamed("amber")
        case .sailingsCancelled:
            self.labelStatus.setText("CANCELLED")
            self.imageStatus.setImageNamed("red")
        case .unknown:
            self.labelStatus.setText("UNKNOWN")
            self.imageStatus.setImageNamed("grey")
        }
        
        if let ports = service.ports {
            configureMapWithPorts(ports)
        }
    }
    
    fileprivate func configureMapWithPorts(_ ports: [Port]) {
        var coordinates = [CLLocationCoordinate2D]()
        
        for port in ports {
            let location = CLLocationCoordinate2D(latitude: port.latitude, longitude: port.longitude)
            coordinates.append(location)
            self.map.addAnnotation(location, with: .red)
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
    fileprivate func fetchDisruptionDetails() {
        guard let service = self.service else {
            return
        }
        
        guard self.dataTask?.state != .running else {
            return
        }
        
        if let lastFetchTime = self.lastFetchTime {
            let secondsSinceLastFetch = Date().timeIntervalSince(lastFetchTime)
            guard secondsSinceLastFetch > ServiceDetailInterfaceController.cacheTimeoutSeconds else {
                self.configureView()
                return
            }
        }
        
        self.configureLoadingView()
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let url = URL(string: "http://www.scottishferryapp.com/services/\(service.serviceId)")!
        
        ProcessInfo().performExpiringActivity(withReason: "Download ferry service details") { expired in
            guard !expired else {
                semaphore.signal()
                return
            }
            
            let timeout = DispatchTime.now() + Double(Int64(30 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            let _ = semaphore.wait(timeout: timeout)
        }
        
        dataTask = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
            defer {
                semaphore.signal()
            }
            
            guard self != nil else {
                return
            }
            
            guard error == nil else {
                DispatchQueue.main.async(execute: {
                    self?.configureErrorViewWithMessage(ServiceDetailInterfaceController.connectionErrorMessage)
                    self?.lastFetchTime = nil
                })
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject] {
                    DispatchQueue.main.async(execute: {
                        if let service = Service(json: jsonDictionary) {
                            self?.service =  service
                            self?.configureView()
                            self?.lastFetchTime = Date()
                        }
                        else {
                            self?.configureErrorViewWithMessage("There was a problem with the server response.")
                            self?.lastFetchTime = nil
                        }
                    })
                }
                
            } catch let error as NSError {
                print("Error parsing json: \(error.localizedDescription)")
                DispatchQueue.main.async(execute: {
                    self?.configureErrorViewWithMessage("There was a problem with the server response.")
                    self?.lastFetchTime = nil
                })
            }
        }) 
        
        dataTask?.resume()
    }

    // MARK: -
    fileprivate func calculateMapRectForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        return coordinates.reduce(MKMapRectNull) { rect, coordinate in
            let point = MKMapPointForCoordinate(coordinate)
            return MKMapRectUnion(rect, MKMapRect(origin: point, size: MKMapSize(width: 0.0, height: 0.0)))
        }
    }
}
