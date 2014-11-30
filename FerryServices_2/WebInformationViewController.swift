//
//  DisruptionInformationViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class WebInformationViewController: UIViewController {
    
    @IBOutlet var webView: UIWebView!
    
    var html: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let html = self.html {
            let styledHtml = "<style type='text/css'>body {font: normal 14px HelveticaNeue; color: #555555;}</style>" + html
            webView.loadHTMLString(styledHtml, baseURL: nil)
        }
    }
}
