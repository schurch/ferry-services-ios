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
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let errorMessage = context as? String {
            labelErrorMessage.setText(errorMessage)
        }
    }
    
    @IBAction func touchedReload() {
        let appDelegate = WKExtension.shared().delegate as? ExtensionDelegate
        appDelegate?.configureApp()
    }
    
}
