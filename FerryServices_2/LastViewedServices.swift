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
    
    private static let maxRecentItems = 5
    static func register(_ service: Service) {
        var lastViewedServices = sharedDefaults?.array(forKey: "lastViewedServiceIds") as? [Int] ?? [Int]()
        
        if let existingIndex = lastViewedServices.index(of: service.id) {
            lastViewedServices.remove(at: existingIndex)
        }
        
        lastViewedServices.insert(service.id, at: 0)
        
        if lastViewedServices.count > maxRecentItems {
            lastViewedServices = Array(lastViewedServices[0..<maxRecentItems])
        }
        
        sharedDefaults?.set(lastViewedServices, forKey: "lastViewedServiceIds")
        
        let services = ServiceStatus.defaultServices
        let shortcutItems: [UIApplicationShortcutItem] = lastViewedServices.dropFirst().compactMap { serviceId in
            guard let service = services.filter({ $0.id == serviceId }).first else { return nil }
            
            let userInfo = [AppDelegate.applicationShortcutUserInfoKeyServiceId : serviceId]
            return UIMutableApplicationShortcutItem(type: AppDelegate.applicationShortcutTypeRecentService, localizedTitle: service.area, localizedSubtitle: service.route, icon: nil, userInfo: userInfo)
        }
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
    private static let mapZoomOutScale = 3.0
    static func registerMapSnapshot(_ annotations: [MKPointAnnotation], completion: (() -> Void)? = nil) {
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
        // Offset y slightly so annotations look more centered
        mapRect.origin.y = mapRect.origin.y - (mapRect.size.height * 0.1)
        
        snapshotterOptions.mapRect = mapRect
        
        let snapshotter = MKMapSnapshotter(options: snapshotterOptions)
        snapshotter.start { snapshot, error in
            guard error == nil else {
                sharedDefaults?.set(nil, forKey: "mapImage")
                return
            }
            
            guard let snapshot = snapshot else {
                sharedDefaults?.set(nil, forKey: "mapImage")
                return
            }
            
            let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            
            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            snapshot.image.draw(at: CGPoint.zero)
            
            for annotation in annotations {
                var point = snapshot.point(for: annotation.coordinate)
                
                let pinScale = CGFloat(0.5)
                let newSize = CGSize(width: pin.image!.size.width * pinScale, height: pin.image!.size.height * pinScale)
                
                point.x = point.x + pin.centerOffset.x * pinScale - (newSize.width / 2)
                point.y = point.y + pin.centerOffset.y * pinScale - (newSize.height / 2)
                
                let pinImage = pin.image!.scale(to: newSize)
                
                pinImage.draw(at: point)
            }
            
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            let imageData = UIImagePNGRepresentation(compositeImage!)
            sharedDefaults?.set(imageData, forKey: "mapImage")
            
            completion?()
        }
    }
}
