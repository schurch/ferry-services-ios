//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailTableViewController: UITableViewController {
    
    var serviceId: Int?;
    
    // MARK: private var
    private var locations: [Location]?
    
    // MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
        
        NSLog("")
    }
    
    // MARK: refresh
    private func refresh () -> () {
        if let serviceId = self.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                
                println(disruptionDetails)
                println(routeDetails)
            }
            
            self.locations = Location.fetchLocationsForSericeId(serviceId)
        }
    }
}
