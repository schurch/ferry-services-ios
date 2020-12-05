//
//  LastViewedServices.swift
//  FerryServices_2
//
//  Created by Stefan Church on 5/11/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

struct LastViewedServices {
    
    private static let maxRecentItems = 4
    static func register(_ service: Service) {
        var lastViewedServices = sharedDefaults?.array(forKey: "lastViewedServiceIds") as? [Int] ?? [Int]()
        
        if let existingIndex = lastViewedServices.firstIndex(of: service.serviceId) {
            lastViewedServices.remove(at: existingIndex)
        }
        
        lastViewedServices.insert(service.serviceId, at: 0)
        
        if lastViewedServices.count > maxRecentItems {
            lastViewedServices = Array(lastViewedServices[0..<maxRecentItems])
        }
        
        sharedDefaults?.set(lastViewedServices, forKey: "lastViewedServiceIds")
        
        let services = Service.defaultServices
        let shortcutItems: [UIApplicationShortcutItem] = lastViewedServices.compactMap { serviceId in
            guard let service = services.filter({ $0.serviceId == serviceId }).first else { return nil }
            
            let userInfo = [AppDelegate.applicationShortcutUserInfoKeyServiceId: serviceId as NSSecureCoding]
            return UIMutableApplicationShortcutItem(type: AppDelegate.applicationShortcutTypeRecentService, localizedTitle: service.area, localizedSubtitle: service.route, icon: nil, userInfo: userInfo)
        }
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
}
