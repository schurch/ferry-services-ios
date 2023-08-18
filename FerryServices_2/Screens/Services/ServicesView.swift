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
            case .single(let services):
                ForEach(services) { service in
                    Button {
                        showService(service)
                    } label: {
                        ServiceRow(service: service)
                    }
                }
                
            case .multiple(let sections):
                ForEach(sections) { section in
                    Section {
                        ForEach(section.services) { service in
                            Button {
                                showService(service)
                            } label: {
                                ServiceRow(service: service)
                            }
                        }
                    } header: {
                        HStack {
                            if let imageName = section.image {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                            }
                            Text(section.title)
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.bottom, 10)
                    }
                }
                
            }
        }
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

private struct ServiceRow: View {
    var service: Service
    
    var body: some View {
        HStack {
            Circle()
                .fill(service.statusColor)
                .frame(width: 25, height: 25, alignment: .center)
                .padding(.trailing, 4)
            VStack(alignment: .leading, spacing: 0) {
                Text(service.area)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(service.route)
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

extension ServicesView {
    
    // Used for bridging to the existing UIKit code
    static func createViewController(
        navigationController: UINavigationController
    ) -> UIViewController {
        let servicesView = ServicesView(
            showService: { service in
                let serviceDetailsViewController = ServiceDetailsView.createViewController(
                    serviceID: service.id,
                    service: service,
                    navigationController: navigationController
                )
                
                navigationController.pushViewController(serviceDetailsViewController, animated: true)
            }
        )
        
        let viewController = UIHostingController(rootView: servicesView)
        viewController.title = "Services"
        
        return viewController
    }
    
}
