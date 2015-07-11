//
//  Utility.swift
//  FerryServices_2
//
//  Created by Stefan Church on 11/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import Foundation

func delay(delay: Double, closure: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), closure)
}
