//
//  DisruptionInformationViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import SafariServices

class WebInformationViewController: UIViewController {
    
    @IBOutlet var webView: UIWebView!
    
    var html: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        if let html = self.html {
            let styledHtml = "<style type='text/css'>body {font: normal 14px HelveticaNeue; color: #555555;}</style>" + html
            webView.loadHTMLString(styledHtml, baseURL: nil)
        }
    }
}

extension WebInformationViewController: UIWebViewDelegate {
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard navigationType == .LinkClicked else { return true }
        guard let url = request.URL else { return true }
        
        let safariViewController = SFSafariViewController(URL: url)
        presentViewController(safariViewController, animated: true, completion: nil)
        
        return false
    }
}
