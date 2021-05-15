//
//  CircleView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 15/05/21.
//  Copyright © 2021 Stefan Church. All rights reserved.
//

import UIKit

class CircleView: UIView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.cornerRadius = frame.size.width / 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.width / 2
    }

}
