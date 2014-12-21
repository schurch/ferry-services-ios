//
//  TimetablePreviewViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 20/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetablePreviewViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webview: UIWebView!
    
    var serviceStatus: ServiceStatus!
    var url: NSURL!
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.translucent = false
        
        let request = NSURLRequest(URL: url)
        webview.loadRequest(request)
        
        let shareItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        self.navigationItem.rightBarButtonItem = shareItem
    }
    
    // MARK: -
    override func viewDidLayoutSubviews() {
        for view in self.webview.subviews as [UIView] {
            for subview in view.subviews as [UIView] {
                subview.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    //MARK: - Share action
    func share() {
        var items = [AnyObject]()
        
        if let route = serviceStatus.route {
            items.append(route)
        }
        
        let pdfData = NSData(contentsOfFile: url.absoluteString!)
        items.append(pdfData!)
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.navigationController?.presentViewController(activityViewController, animated: true, completion: {})
    }
}
