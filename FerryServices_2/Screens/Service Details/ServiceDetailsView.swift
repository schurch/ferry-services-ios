//
//  ServiceDetailsView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/07/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI
import MapKit
import Combine

struct ServiceDetailsView: View {
    
    @StateObject private var viewModel: ServiceDetailsViewModel
    @State private var showingDateSelection = false
    @Environment(\.openURL) private var openURL
    private var mapPosition: Binding<MapCameraPosition> {
        Binding(
            get: {
                .rect(viewModel.mapRect)
            },
            set: { newPosition in
                if let rect = newPosition.rect {
                    viewModel.mapRect = rect
                }
            }
        )
    }
    
    var showDisruptionInfo: (String) -> Void
    var showMap: (Service) -> Void
    
    init(
        serviceID: Int,
        service: Service?,
        showDisruptionInfo: @escaping (String) -> Void,
        showMap: @escaping (Service) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ServiceDetailsViewModel(
                serviceID: serviceID,
                service: service
            )
        )
        self.showDisruptionInfo = showDisruptionInfo
        self.showMap = showMap
    }
    
    var body: some View {
        if let service = viewModel.service {
            List {
                ServiceDetailsHeaderSectionView(
                    service: service,
                    annotations: viewModel.annotations,
                    mapPosition: mapPosition,
                    showMap: showMap
                )

                ServiceDetailsStatusSectionView(
                    service: service,
                    isEnabledForNotifications: viewModel.isEnabledForNotifications,
                    isRegisteredForNotifications: viewModel.isRegisteredForNotifications,
                    loadingSubscribed: viewModel.loadingSubscribed,
                    subscribed: $viewModel.subscribed,
                    updateSubscribed: { viewModel.updateSubscribed(subscribed: $0) },
                    openNotificationSettings: {
                        if let url = viewModel.notificationSettingsURL {
                            openURL(url)
                        }
                    },
                    showDisruptionInfo: showDisruptionInfo
                )
                
                ForEach(viewModel.sortedLocationsByName) { location in
                    Section {
                        LocationInformation(location: location)
                    }
                    .padding(.top, 8)
                    .listRowSeparator(.hidden)
                }
                
                if viewModel.shouldShowScheduledDepartures {
                    Section {
                        HStack(alignment: .center) {
                            Button {
                                showingDateSelection = true
                            } label: {
                                Text("\(ServiceDetailsViewModel.Copy.departureDatePrefix)\(viewModel.selectedDateValueTitle)")
                                    .foregroundColor(.colorTint)
                            }
                        }
                        .font(.body)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowSeparator(.hidden)
                        
                        HStack(alignment: .top) {
                            if viewModel.showScheduledDepartureWarning {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.colorAmber)
                            }

                            Text(LocalizedStringKey(viewModel.scheduledDepartureInfoText))
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.systemGray))
                                .environment(\.openURL, OpenURLAction { url in
                                    if url.absoluteString == ServiceDetailsViewModel.Copy.moreInfoURL,
                                        let additionalInfo = service.additionalInfo
                                    {
                                        showDisruptionInfo(additionalInfo)
                                        return .handled
                                    } else {
                                        return .systemAction
                                    }
                                })
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowSeparator(.hidden)
                    }
                    
                    ForEach(viewModel.scheduledDepartureSections) { section in
                        Section {
                            ForEach(section.rows) { row in
                                HStack {
                                    Text(row.departureTimeText)
                                        .accessibilityLabel(row.departureAccessibilityText)
                                    
                                    Spacer()
                                    
                                    Text(row.arrivalTimeText)
                                        .accessibilityLabel(row.arrivalAccessibilityText)
                                }
                                .foregroundColor(row.isPastDeparture ? Color(UIColor.systemGray2) : Color(UIColor.label))
                                .accessibilityElement(children: .combine)
                            }
                        } header: {
                            HStack {
                                Text(section.originName)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .accessibilityLabel("to")
                                Spacer()
                                Text(section.destinationName)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                
                if let serviceOperator = viewModel.serviceOperator {
                    Section {
                        ServiceOperator(serviceOperator: serviceOperator)
                            .padding([.top, .bottom], 5)
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .sheet(
                isPresented: $showingDateSelection,
                onDismiss: {
                    Task {
                        await viewModel.fetchLatestService()
                    }
                }
            ) {
                NavigationView {
                    DatePicker(
                        ServiceDetailsViewModel.Copy.departureDatePickerTitle,
                        selection: $viewModel.date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .navigationTitle(ServiceDetailsViewModel.Copy.departureDatePickerTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(ServiceDetailsViewModel.Copy.doneButtonTitle) {
                                showingDateSelection = false
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
            }
            .alert(ServiceDetailsViewModel.Copy.errorAlertTitle, isPresented: $viewModel.showSubscribedError) {
                Button(ServiceDetailsViewModel.Copy.okButtonTitle, role: .cancel) { }
            } message: {
                Text(ServiceDetailsViewModel.Copy.errorAlertMessage)
            }
            .task {
                await viewModel.fetchLatestService()
            }
            .refreshable {
                await viewModel.fetchLatestService()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshFromAppActivation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .registeredForNotifications), perform: { _ in
                viewModel.checkIsRegisteredForNotifications()
            })
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack(spacing: 12) {
                if viewModel.failedToLoadService {
                    Text(ServiceDetailsViewModel.Copy.failedToLoadMessage)
                        .foregroundStyle(.secondary)
                    Button(ServiceDetailsViewModel.Copy.retryButtonTitle) {
                        Task {
                            await viewModel.fetchLatestService()
                        }
                    }
                } else {
                    ProgressView(ServiceDetailsViewModel.Copy.loadingTitle)
                    Button(ServiceDetailsViewModel.Copy.retryButtonTitle) {
                        Task {
                            await viewModel.fetchLatestService()
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchLatestService()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await viewModel.fetchLatestService()
                }
            }
                .navigationTitle(viewModel.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}

private extension ServiceDetailsView {
    func refreshFromAppActivation() {
        Task {
            await viewModel.handleDidBecomeActive()
        }
    }
}
