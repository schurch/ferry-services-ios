//
//  FerryServicesApp.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation
import SwiftUI

enum UserDefaultsKeys {
    static let subscribedService = "com.ferryservices.userdefaultkeys.subscribedservices.v2"
    static let registeredForNotifications = "com.ferryservices.userdefaultkeys.registeredForNotifications"
}

struct Installation {
    static let id: UUID = {
        let key = "installationID"
        
        if let id = UserDefaults.standard.string(forKey: key) {
            return UUID(uuidString: id)!
        } else {
            let id = UUID()
            UserDefaults.standard.set(id.uuidString, forKey: key)
            return id
        }
    }()
}

@main
struct FerryServicesApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ServicesView()
                .accentColor(Color("Tint"))
        }
    }
    
}
