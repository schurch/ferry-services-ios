//
//  LoadingInterfaceController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 1/08/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommonWatch
import CoreLocation

enum LocationLoaderError: ErrorType {
    case UnableToCreateFilePath
    case FileMissing
    case ProblemReadingFile
}

class LoaderInterfaceController: WKInterfaceController {
    
    @IBOutlet var labelLoading: WKInterfaceLabel!
    
    let locationManager = CLLocationManager()
    
    var isRequestingLocation = false
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        do {
            let locations = try self.getLocations()
            locations.forEach { location in
                print("Name: \(location.name)\n")
            }
        }
        catch {
            print("Error getting locations")
        }
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        if let recentServiceIds = NSUserDefaults.standardUserDefaults().arrayForKey("recentServiceIds") as? [Int] {
            if recentServiceIds.count > 0 {
                ServicesAPIClient.sharedInstance.fetchFerryServicesWithCompletion { services, error in
                    guard let services = services else {
                        return
                    }
                    
                    let recentServices = services.filter { service in
                        if let serviceId = service.serviceId {
                            return recentServiceIds.contains(serviceId)
                        }
                        
                        return false
                    }
                    
                    let controllers = Array(count: recentServiceIds.count, repeatedValue: "serviceDetail")
                    WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: recentServices)
                }
            }
            else {
                self.requestLocation()
            }
        }
        else {
            self.requestLocation()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func requestLocation() {
        guard !self.isRequestingLocation else {
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        switch authorizationStatus {
        case .NotDetermined:
            isRequestingLocation = true
            self.labelLoading.setText("Looking for nearest port...")
            self.locationManager.requestWhenInUseAuthorization()
            
        case .AuthorizedWhenInUse:
            isRequestingLocation = true
            self.labelLoading.setText("Looking for nearest port...")
            self.locationManager.requestLocation()
            
        case .Denied:
            self.labelLoading.setText("Unable to determine location. Please enable location services on your phone.")
            
        default:
            self.labelLoading.setText("Unexpected authorization status.")
        }
        
        self.isRequestingLocation = true
        
        self.locationManager.requestLocation()
    }
    
    func getLocations() throws -> [Location] {
        guard let locationsFilePath = NSBundle.mainBundle().pathForResource("locations", ofType: "csv") else  {
            throw LocationLoaderError.UnableToCreateFilePath
        }
        
        guard NSFileManager.defaultManager().fileExistsAtPath(locationsFilePath) else {
            throw LocationLoaderError.FileMissing
        }
        
        guard let csvContents = NSString.stringWithContentsOfFile(locationsFilePath) else {
            throw LocationLoaderError.ProblemReadingFile
        }
        
        let lines = csvContents.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        return lines.map { (line: String) -> (Location) in
            let components = line.componentsSeparatedByString(",")
            
            let latitude = Double(components[2])!
            let longitude = Double(components[3])!
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            return Location(locationId: Int(components[0])!, name: components[1], coordinates: coordinates)
        }
    }
}

extension LoaderInterfaceController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            let lastLocationCoordinate = locations.last!.coordinate
            print("Location: \(lastLocationCoordinate)")
            
            self.isRequestingLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Error fetching location: \(error)")
            
            self.labelLoading.setText("Error trying to find nearest port.")
            self.isRequestingLocation = false
        }
    }
}
