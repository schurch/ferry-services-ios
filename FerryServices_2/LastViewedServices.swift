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
    
    static func register(_ service: ServiceStatus) {
        guard let serviceId = service.serviceId else { return }
        
        var lastViewedServices = sharedDefaults?.array(forKey: "lastViewedServiceIds") as? [Int] ?? [Int]()
        lastViewedServices.insert(serviceId, at: 0)
        
        if lastViewedServices.count > 5 {
            lastViewedServices = Array(lastViewedServices[0..<5])
        }
        
        sharedDefaults?.set(lastViewedServices, forKey: "lastViewedServiceIds")
        
        let services = ServiceStatus.defaultServices
        let shortcutItems: [UIApplicationShortcutItem] = lastViewedServices.dropFirst().flatMap { serviceId in
            guard let service = services.filter({ $0.serviceId == serviceId }).first else { return nil }
            guard let area = service.area, let route = service.route else { return nil }
            
            let userInfo = [AppDelegate.applicationShortcutUserInfoKeyServiceId : serviceId]
            return UIMutableApplicationShortcutItem(type: AppDelegate.applicationShortcutTypeRecentService, localizedTitle: area, localizedSubtitle: route, icon: nil, userInfo: userInfo)
        }
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
    private static let mapZoomOutScale = 3.0
    static func registerMapSnapshot(_ annotations: [MKPointAnnotation]) {
        let snapshotterOptions = MKMapSnapshotOptions()
        snapshotterOptions.size = CGSize(width: 70, height: 70)
        
        var mapRect = calculateMapRectForAnnotations(annotations)
        
        let originalHeight = mapRect.size.height
        let originalWidth = mapRect.size.width
        let newHeight = mapRect.size.height * mapZoomOutScale
        let newWidth = mapRect.size.width * mapZoomOutScale
        
        mapRect.size.height = newHeight
        mapRect.size.width = newWidth
        mapRect.origin.x = mapRect.origin.x - ((newWidth - originalWidth) / 2.0)
        mapRect.origin.y = mapRect.origin.y - ((newHeight - originalHeight) / 2.0)
        
        snapshotterOptions.mapRect = mapRect
        
        let snapshotter = MKMapSnapshotter(options: snapshotterOptions)
        snapshotter.start { snapshot, error in
            guard error == nil else {
                sharedDefaults?.set(nil, forKey: "mapImage")
                return
            }
            
            guard let image = snapshot?.image else {
                sharedDefaults?.set(nil, forKey: "mapImage")
                return
            }
            
            let imageData = UIImagePNGRepresentation(image)
            sharedDefaults?.set(imageData, forKey: "mapImage")
        }
    }
}
