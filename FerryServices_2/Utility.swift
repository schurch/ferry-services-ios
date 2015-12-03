//
//  Utility.swift
//  FerryServices_2
//
//  Created by Stefan Church on 11/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import Foundation
import MapKit

func delay(delay: Double, closure: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), closure)
}

func calculateMapRectForAnnotations(annotations: [MKPointAnnotation]) -> MKMapRect {
    var mapRect = MKMapRectNull
    for annotation in annotations {
        let point = MKMapPointForCoordinate(annotation.coordinate)
        mapRect = MKMapRectUnion(mapRect, MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
    }
    return mapRect
}
