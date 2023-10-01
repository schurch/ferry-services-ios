//
//  ServicesView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI

struct ServicesView: View {
    
    var showService: (Service) -> Void
    
    @StateObject private var model = ServicesModel()
    
    var body: some View {
        List {
            switch model.sections {
            case .single(let rows):
                ForEach(rows) { row in
                    ServiceRow(row: row, showService: showService)
                }
                
            case .multiple(let sections):
                ForEach(sections) { section in
                    ServicesSection(section: section, showService: showService)
                }
            }
        }
        .background(.colorBackground)
        .scrollContentBackground(.hidden)
        .searchable(text: $model.searchText)
        .autocorrectionDisabled()
        .task {
            await model.fetchServices()
        }
        .refreshable {
            await model.fetchServices()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await model.fetchServices()
            }
        }
    }
}

private struct ServicesSection: View {
    var section: ServicesModel.Sections.Section
    var showService: (Service) -> Void
    
    var body: some View {
        Section(section.title) {
            ForEach(section.rows) { row in
                ServiceRow(row: row, showService: showService)
            }
        }
    }
}

private struct ServiceRow: View {
    var row: ServicesModel.Sections.Row
    var showService: (Service) -> Void
    
    var body: some View {
        Button {
            showService(row.service)
        } label: {
            HStack {
                Circle()
                    .fill(row.service.status.statusColor)
                    .frame(width: 25, height: 25, alignment: .center)
                    .padding(.trailing, 4)
                VStack(alignment: .leading, spacing: 0) {
                    Text(row.service.area)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(row.service.route)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(Font.system(.caption).weight(.bold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.top, 2)
            .padding(.bottom, 2)
        }
    }
}

extension ServicesView {
    
    // Used for bridging to the existing UIKit code
    static func createViewController(
        navigationController: UINavigationController
    ) -> UIViewController {
        let servicesView = ServicesView(
            showService: { service in
                let serviceDetailsViewController = ServiceDetailsView.createViewController(
                    serviceID: service.serviceId,
                    service: service,
                    navigationController: navigationController
                )
                
                navigationController.pushViewController(serviceDetailsViewController, animated: true)
            }
        )
        
        let viewController = UIHostingController(rootView: servicesView)
        viewController.title = String(localized: "Services")
        
        return viewController
    }
    
}
