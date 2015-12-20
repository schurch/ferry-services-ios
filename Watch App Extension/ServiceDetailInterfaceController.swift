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
    
    @IBOutlet var labelArea: WKInterfaceLabel!
    @IBOutlet var labelDisruptionInformation: WKInterfaceLabel!
    @IBOutlet var labelRoute: WKInterfaceLabel!
    @IBOutlet var labelStatus: WKInterfaceLabel!
    @IBOutlet var labelViewOnPhone: WKInterfaceLabel!
    @IBOutlet var imageStatus: WKInterfaceImage!
    @IBOutlet var separator: WKInterfaceSeparator!
    
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
        
        if let service = self.service {
            self.updateUserActivity("com.stefanchurch.ferryservices.viewservice", userInfo: ["serviceId": service.serviceId], webpageURL: nil)
        }
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
        
        NSProcessInfo().performExpiringActivityWithReason("Download ferry service details") { expired in
            guard !expired else {
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * Double(NSEC_PER_SEC)))
            dispatch_semaphore_wait(semaphore, timeout)
        }

        let url = NSURL(string: "http://stefanchurch.com:4567/services/\(service.serviceId)")!
        print("Fetching from \(url)")
        
        dataTask = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
            defer {
                dispatch_semaphore_signal(semaphore)
            }
            
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.configureErrorViewWithMessage("There was an error. Please check your connection.")
                    self.lastFetchTime = nil
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
                            self.service =  service
                            self.configureView()
                            self.lastFetchTime = NSDate()
                        }
                        else {
                            self.configureErrorViewWithMessage("There was a problem with the server response.")
                            self.lastFetchTime = nil
                        }
                    })
                }
                
            } catch let error as NSError {
                print("Error parsing json: \(error.localizedDescription)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.configureErrorViewWithMessage("There was a problem with the server response.")
                    self.lastFetchTime = nil
                })
            }
        }
        
        dataTask?.resume()
    }
    
    // MARK: - View configuration
    private func configureLoadingView() {
        if let service = self.service {
            self.labelRoute.setText(service.route)
        }
        
        self.labelStatus.setText("Loading...")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImageNamed("grey")
        self.separator.setHidden(false)
        self.labelViewOnPhone.setHidden(true)
    }
    
    private func configureErrorViewWithMessage(message: String) {
        self.labelArea.setText("")
        self.labelRoute.setText(message)
        self.labelStatus.setText("")
        self.labelDisruptionInformation.setText("")
        self.imageStatus.setImage(nil)
        self.separator.setHidden(true)
        self.labelViewOnPhone.setHidden(true)
    }
    
    private func configureView() {
        guard let service = self.service else {
            return
        }
        
        self.setTitle(service.area)
        
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
            self.labelStatus.setText("Normal")
            self.imageStatus.setImageNamed("green")
        case .SailingsAffected:
            self.labelStatus.setText("Disrupted")
            self.imageStatus.setImageNamed("amber")
        case .SailingsCancelled:
            self.labelStatus.setText("Cancelled")
            self.imageStatus.setImageNamed("red")
        case .Unknown:
            self.labelStatus.setText("Unknown")
            self.imageStatus.setImageNamed("grey")
        }
        
        self.separator.setHidden(false)
        self.labelViewOnPhone.setHidden(false)
    }

}
