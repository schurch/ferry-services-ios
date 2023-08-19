//
//  ServicesView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI

struct ServicesView: View {
    
    struct ServiceNavigationData: Identifiable, Hashable {
        let id = UUID()
        let serviceID: Int
        let service: Service?
    }
    
    @StateObject private var model = ServicesModel()
    @State private var presentedService: [ServiceNavigationData] = []
    @EnvironmentObject private var appDelegate: AppDelegate
    
    var body: some View {
        NavigationStack(path: $presentedService) {
            List {
                switch model.sections {
                case .single(let services):
                    ForEach(services) { service in
                        NavigationLink(
                            value: ServiceNavigationData(
                                serviceID: service.id,
                                service: service
                            )
                        ) {
                            ServiceRow(service: service)
                        }
                    }
                    
                case .multiple(let sections):
                    ForEach(sections) { section in
                        Section(section.title) {
                            ForEach(section.services) { service in
                                NavigationLink(
                                    value: ServiceNavigationData(
                                        serviceID: service.id,
                                        service: service
                                    )
                                ) {
                                    ServiceRow(service: service)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color("Background"))
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
            .navigationDestination(for: ServiceNavigationData.self) { navigationData in
                ServiceDetailsView(serviceID: navigationData.serviceID, service: navigationData.service)
            }
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: appDelegate.presentedServiceID) { serviceID in
                guard let serviceID else { return }
                presentedService = [ServiceNavigationData(serviceID: serviceID, service: nil)]
            }
            .alert(
                "Alert",
                isPresented: $appDelegate.showNotificationMessage
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appDelegate.notificationMessage)
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
        }
        .padding(.top, 2)
        .padding(.bottom, 2)
    }
}
