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
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    },
                    showDisruptionInfo: showDisruptionInfo
                )
                
                ForEach(service.locations.sorted(by: { $0.name < $1.name })) { location in
                    Section {
                        LocationInformation(location: location)
                    }
                    .padding(.top, 8)
                    .listRowSeparator(.hidden)
                }
                
                if service.scheduledDeparturesAvailable == true {
                    Section {
                        HStack(alignment: .center) {
                            Button {
                                showingDateSelection = true
                            } label: {
                                Text("Departures on ")
                                +
                                Text(viewModel.date.formatted(.dateTime.weekday().year().month().day()))
                                    .bold()
                                    .foregroundColor(.colorTint)
                            }
                        }
                        .font(.body)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowSeparator(.hidden)
                        
                        HStack(alignment: .top) {
                            if [Service.Status.cancelled, .disrupted, .unknown].contains(service.status) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.colorAmber)
                            }
                            
                            let moreInfoURL = "ferryservices://more-info"
                            
                            let text = {
                                let additionalInfo = if !(service.additionalInfo ?? "").isEmpty {
                                    "[up to date information](\(moreInfoURL))"
                                } else {
                                    "up to date information"
                                }
                                
                                let website = if let website = service.operator?.website, !website.isEmpty {
                                    "[website](\(website))"
                                } else {
                                    "website"
                                }
                                
                                return "Scheduled departure times provided by [Traveline](https://www.traveline.info). Sailings may not be operating to the scheduled departure times. Please check the most \(additionalInfo) from the ferry service operator or their \(website) for more details."
                            }()
                            
                            Text(LocalizedStringKey(text))
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.systemGray))
                                .environment(\.openURL, OpenURLAction { url in
                                    if url.absoluteString == moreInfoURL,
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
                    
                    ForEach(service.locations.sorted(by: { $0.scheduledDepartures?.first?.departure ?? Date() < $1.scheduledDepartures?.first?.departure ?? Date() })) { location in
                        ForEach(location.groupedScheduledDepartures, id: \.self.first?.destination.id) { departures in
                            Section {
                                ForEach(departures) { departureInfo in
                                    HStack {
                                        let departureTime = departureInfo
                                            .departure
                                            .formatted(Date.timeFormatStyle)
                                        Text(departureTime)
                                            .accessibilityLabel("\(departureTime) departure")
                                        
                                        Spacer()
                                        
                                        let arrivalTime = departureInfo
                                            .arrival
                                            .formatted(Date.timeFormatStyle)
                                        Text(arrivalTime)
                                            .accessibilityLabel("\(arrivalTime) arrival")
                                    }
                                    .foregroundColor(departureInfo.departure > Date() ? Color(UIColor.label) : Color(UIColor.systemGray2))
                                    .accessibilityElement(children: .combine)
                                }
                            } header: {
                                HStack {
                                    let destinationName = departures.first?.destination.name ?? ""
                                    Text(location.name)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .accessibilityLabel("to")
                                    Spacer()
                                    Text(destinationName)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                
                if let serviceOperator = service.operator {
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
                        "Departure Date",
                        selection: $viewModel.date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .navigationTitle("Departure Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingDateSelection = false
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
            }
            .alert("Error", isPresented: $viewModel.showSubscribedError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A problem occured. Please try again later.")
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
            .navigationTitle(service.area)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack(spacing: 12) {
                if viewModel.failedToLoadService {
                    Text("Unable to load this service right now.")
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchLatestService()
                        }
                    }
                } else {
                    ProgressView("Loading...")
                    Button("Retry") {
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
                .navigationTitle("Service")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}

private extension ServiceDetailsView {
    func refreshFromAppActivation() {
        Task {
            await viewModel.fetchLatestService()
            await viewModel.checkIsEnabledForNotifications()
        }
    }
}
