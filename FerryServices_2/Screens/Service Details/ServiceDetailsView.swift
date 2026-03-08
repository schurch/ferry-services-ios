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
    
    @StateObject private var model: ServiceDetailModel
    @State private var showingDateSelection = false
    @Environment(\.openURL) private var openURL
    private var mapPosition: Binding<MapCameraPosition> {
        Binding(
            get: {
                .rect(model.mapRect)
            },
            set: { newPosition in
                if let rect = newPosition.rect {
                    model.mapRect = rect
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
        _model = StateObject(
            wrappedValue: ServiceDetailModel(
                serviceID: serviceID,
                service: service
            )
        )
        self.showDisruptionInfo = showDisruptionInfo
        self.showMap = showMap
    }
    
    var body: some View {
        if let service = model.service {
            List {
                Section {
                    VStack(spacing: 0) {
                        if !model.annotations.isEmpty {
                            Map(
                                position: mapPosition,
                                interactionModes: []
                            ) {
                                ForEach(model.annotations) { annotation in
                                    MapKit.Annotation("", coordinate: annotation.coordinate) {
                                        switch annotation.type {
                                        case .vessel(let course):
                                            Image("ferry")
                                                .rotationEffect(.degrees(course))
                                        case .location:
                                            Image("map-annotation")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .onTapGesture {
                                showMap(service)
                            }
                        }
                        
                        VStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.area)
                                    .font(.title)
                                Text(service.route)
                            }
                            .font(.body)
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                
                Section {
                    Group {
                        if let additionalInfo = service.additionalInfo, !additionalInfo.isEmpty {
                            Button {
                                showDisruptionInfo(additionalInfo)
                            } label: {
                                DisruptionInfoView(service: service)
                            }
                        } else {
                            DisruptionInfoView(service: service)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    
                    if model.isEnabledForNotifications {
                        if model.isRegisteredForNotifications {
                            if model.loadingSubscribed {
                                HStack {
                                    Text("Subscribe to updates")
                                    Spacer()
                                    // Progress view sometimes wouldn't show again so give it a unique ID each time
                                    ProgressView()
                                        .id(UUID())
                                        .padding(.trailing, 12)
                                }
                                .listRowSeparator(.hidden)
                            } else {
                                Toggle("Subscribe to updates", isOn: $model.subscribed)
                                    .onChange(of: model.subscribed) { value in
                                        model.updateSubscribed(subscribed: value)
                                    }
                                    .listRowSeparator(.hidden)
                            }
                        }
                    } else {
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            NavigationLink("Enable notifications to subscribe", destination: EmptyView())
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                
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
                                Text(model.date.formatted(.dateTime.weekday().year().month().day()))
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
                        await model.fetchLatestService()
                    }
                }
            ) {
                NavigationView {
                    DatePicker(
                        "Departure Date",
                        selection: $model.date,
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
            .alert("Error", isPresented: $model.showSubscribedError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A problem occured. Please try again later.")
            }
            .task {
                await model.fetchLatestService()
            }
            .refreshable {
                await model.fetchLatestService()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshFromAppActivation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .registeredForNotifications), perform: { _ in
                model.checkIsRegisteredForNotifications()
            })
            .navigationTitle(service.area)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack(spacing: 12) {
                if model.failedToLoadService {
                    Text("Unable to load this service right now.")
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task {
                            await model.fetchLatestService()
                        }
                    }
                } else {
                    ProgressView("Loading...")
                    Button("Retry") {
                        Task {
                            await model.fetchLatestService()
                        }
                    }
                }
            }
            .task {
                await model.fetchLatestService()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await model.fetchLatestService()
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
            await model.fetchLatestService()
            await model.checkIsEnabledForNotifications()
        }
    }
}
