//
//  TimetablePreviewViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 20/09/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import WebKit

class TimetablePreviewViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webview: WKWebView!
    
    var service: Service!
    var url: URL!
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        let request = URLRequest(url: url)
        webview.load(request)
        
        let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(TimetablePreviewViewController.share))
        self.navigationItem.rightBarButtonItem = shareItem
    }
    
    // MARK: -
    override func viewDidLayoutSubviews() {
        for view in self.webview.subviews {
            for subview in view.subviews {
                subview.backgroundColor = UIColor.white
            }
        }
    }
    
    //MARK: - Share action
    @objc func share() {
        var items = [AnyObject]()
        
        items.append(service.route as AnyObject)
        
        let pdfData = try? Data(contentsOf: URL(fileURLWithPath: url.absoluteString))
        items.append(pdfData! as AnyObject)
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.navigationController?.present(activityViewController, animated: true, completion: {})
    }
}
