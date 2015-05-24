//
//  InterfaceController.swift
//  Ferries WatchKit Extension
//
//  Created by Stefan Church on 23/05/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import WatchKit
import Foundation
import FerryServicesCommon

class ServiceListInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!

    // MARK: - Lifecycle
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        WKInterfaceController.openParentApplication(["action": "fetch_service_details"]) { replyInfo, error in
            println(replyInfo!["response"])
        }
        
//        self.configureTableWithData(["Arran", "Bute", "Somewhere else"])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // MARK: - 
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        return "Test"
    }
    
    // MARK: - Table config
    func configureTableWithData(data: [ServiceStatus]) {
//        self.table.setNumberOfRows(data.count, withRowType: "serviceRow")
//        for var index = 0; index < data.count; index++ {
//            let rowData = data[index]
//            
//            let row = self.table.rowControllerAtIndex(index) as! ServiceRow
//            row.serviceLabel.setText(rowData)
//            row.serviceStatusImage.setImageNamed("green")
//        }
    }

}
