//
//  Repeater.swift
//  FerryServices_2
//
//  Created by Stefan Church on 6/02/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import Foundation
import SwiftyTimer

class Repeater {
    
    var timer: NSTimer
    
    init(interval: NSTimeInterval, callback: (Void -> Void)) {
        timer = NSTimer.new(every: interval, callback)
        timer.start()
        callback()
    }
    
    deinit {
        timer.invalidate()
    }
}
