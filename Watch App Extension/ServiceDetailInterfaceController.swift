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
    @IBOutlet var imageStatus: WKInterfaceImage!
    
    var dataTask: NSURLSessionDataTask?
    var lastFetchTime: NSDate?
    var serviceId: Int!
    var serviceData: [String: AnyObject]?

    // MARK: - View lifecycle
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let serviceId = context as? Int {
            self.serviceId = serviceId
        }
    }

    override func willActivate() {
        super.willActivate()
        
        fetchDisruptionDetails()
    }
    
    // MARK: - Utility methods
    private func fetchDisruptionDetails() {
        guard let serviceId = self.serviceId else {
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
        
        let semaphore = dispatch_semaphore_create(0)
        
        NSProcessInfo().performExpiringActivityWithReason("Download ferry service details") { expired in
            guard !expired else {
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * Double(NSEC_PER_SEC)))
            dispatch_semaphore_wait(semaphore, timeout)
        }

        let url = NSURL(string: "http://stefanchurch.com:4567/services/\(serviceId)")!
        print("Fetching from \(url)")
        
        dataTask = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
            defer {
                self.lastFetchTime = NSDate()
                dispatch_semaphore_signal(semaphore)
            }
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject] {
                    self.serviceData = jsonDictionary
                    self.configureView()
                }
                
            } catch let error as NSError {
                print("Error: \(error)")
            }
        }
        
        dataTask?.resume()
    }
    
    private func configureView() {
        if let area = self.serviceData?["area"] as? String,
            let route = self.serviceData?["route"] as? String,
            let status = self.serviceData?["status"] as? Int {
                self.labelArea.setText(area)
                self.labelRoute.setText(route)
                

                if let disruptionDetailsHtml = self.serviceData?["disruption_details"] as? String {
                    if let data = disruptionDetailsHtml.dataUsingEncoding(NSUTF8StringEncoding) {
                        do {
                            let attributeText = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
                            self.labelDisruptionInformation.setAttributedText(attributeText)
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    }  
                }
        
                switch status {
                case 0:
                    self.labelStatus.setText("Normal")
                    self.imageStatus.setImageNamed("green")
                case 1:
                    self.labelStatus.setText("Disrupted")
                    self.imageStatus.setImageNamed("amber")
                case 2:
                    self.labelStatus.setText("Cancelled")
                    self.imageStatus.setImageNamed("red")
                case -99:
                    self.labelStatus.setText("Unknown")
                    self.imageStatus.setImageNamed("grey")
                default:
                    self.labelStatus.setText("Unknown")
                    self.imageStatus.setImageNamed("grey")
                }
        }
    }

}
