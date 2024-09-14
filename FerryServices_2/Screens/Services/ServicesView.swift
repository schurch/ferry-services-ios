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
        .listStyle(.plain)
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
                DisruptionIndicator(status: row.service.status)
                    .padding(.trailing, 4)
                VStack(alignment: .leading, spacing: 0) {
                    Text(row.service.area)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(row.service.route)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    let disruptionText = switch row.service.status {
                    case .normal: "Normal Operations"
                    case .disrupted: "Sailings Disrupted"
                    case .cancelled: "Sailings Cancelled"
                    case .unknown: "Unknown Status"
                    }
                    
                    Text(disruptionText)
                        .font(.subheadline.bold())
                        .foregroundStyle(row.service.status.statusColor)
                        .padding(.top, 5)
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
        viewController.title = NSLocalizedString("Services", comment: "")
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            primaryAction: UIAction { _ in
                let settingsViewController = UIHostingController(rootView: SettingsView())
                settingsViewController.title = NSLocalizedString("Settings", comment: "")
                settingsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    title: NSLocalizedString("Done", comment: ""),
                    primaryAction: UIAction { _ in
                        navigationController.dismiss(animated: true)
                    }
                )
                settingsViewController.navigationItem.rightBarButtonItem?.style = .done
                let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
                settingsNavigationController.navigationBar.prefersLargeTitles = true
                
                navigationController.present(settingsNavigationController, animated: true)
            }
        )
        
        return viewController
    }
    
}
