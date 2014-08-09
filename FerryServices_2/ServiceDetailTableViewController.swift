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
    
    private var location: [Location]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(5) { disruptionsDetails, routeDetails, error in
            
        }
        
        self.location = Location.fetchLocationsForSericeId(5)
        
        NSLog("")
    }
}
