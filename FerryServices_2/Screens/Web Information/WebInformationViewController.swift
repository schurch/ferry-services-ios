//
//  DisruptionInformationViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 22/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import SafariServices
import WebKit

class WebInformationViewController: UIViewController {
    
    @IBOutlet var webView: WKWebView!
    
    var html: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Disruption Information", comment: "")
        webView.navigationDelegate = self
        loadHtml()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            loadHtml()
        }
    }
    
    private func loadHtml() {
        if let html = self.html {
            let styledHtml = """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta name='viewport' content='width=device-width, initial-scale=1'>
                    <style type='text/css'>
                        :root {
                            color-scheme: light dark;
                        }
                        body { font: -apple-system-body; }
                        a { color: #21BFAA; }
                    </style>
                </head>
                <body>
                    \(html)
                </body>
            </html>
            """
            webView.loadHTMLString(styledHtml, baseURL: nil)
        }
    }
}

extension WebInformationViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard 
            navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url
        else {
            decisionHandler(.allow)
            return
        }
                
        switch url.scheme {
        case "http", "https":
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)
            decisionHandler(.cancel)
        case "tel", "mailto":
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
        
        
    }
}
