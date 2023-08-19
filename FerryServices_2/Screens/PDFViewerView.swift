//
//  PDFViewerView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 19/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import Foundation
import SwiftUI
import PDFKit

struct PDFViewerView: UIViewRepresentable {
    
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView  {
        let view = PDFView()
        view.backgroundColor = UIColor(named: "Background")!
        return view
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }

}
