//
//  Utility.swift
//  FerryServices_2
//
//  Created by Stefan Church on 11/07/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import Foundation

func delay(_ delay: Double, closure: @escaping () -> ()) {
    let delayTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delayTime, execute: closure)
}
