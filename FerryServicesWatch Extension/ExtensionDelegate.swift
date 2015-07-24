//
//  ExtensionDelegate.swift
//  FerryServicesWatch Extension
//
//  Created by Stefan Church on 24/07/15.
//  Copyright © 2015 Stefan Church. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        if let serviceListViewController = WKExtension.sharedExtension().rootInterfaceController as? ServiceListInterfaceController {
            serviceListViewController.refreshWithCompletion {
                
            }
        }
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

}
