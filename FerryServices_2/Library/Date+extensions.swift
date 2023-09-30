//
//  NSDate+Additions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/11/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

extension Date {
    static let timeFormatStyle = {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = TimeZone(identifier: "Europe/London")!
        return style
    }()
}
