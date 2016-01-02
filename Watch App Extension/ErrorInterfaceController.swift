//
//  ErrorInterfaceController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 2/01/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation

class ErrorInterfaceController: WKInterfaceController {

    @IBOutlet var labelErrorMessage: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let errorMessage = context as? String {
            labelErrorMessage.setText(errorMessage)
        }
    }
    
    @IBAction func touchedReload() {
        let appDelegate = WKExtension.sharedExtension().delegate as? ExtensionDelegate
        appDelegate?.configureApp()
    }
    
}
