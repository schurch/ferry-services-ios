//
//  DisruptionIndicator.swift
//  FerryServices_2
//
//  Created by Stefan Church on 14/09/2024.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import SwiftUI

struct DisruptionIndicator: View {
    let status: Service.Status
    
    var body: some View {
        ZStack {
            Circle()
                .fill(status.statusColor)
                .frame(width: 10, height: 10, alignment: .center)
            Circle()
                .fill(status.statusColor.opacity(0.3))
                .frame(width: 20, height: 20, alignment: .center)
            Circle()
                .fill(status.statusColor.opacity(0.2))
                .frame(width: 25, height: 25, alignment: .center)
        }
    }
}
