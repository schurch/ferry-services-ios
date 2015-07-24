//
//  Int_extensions.swift
//  FerryServices_2
//
//  Created by Stefan Church on 28/06/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

public extension Double {
    func degreesToRadians() -> CGFloat {
        return CGFloat(M_PI / 180.0) * CGFloat(self)
    }
}
