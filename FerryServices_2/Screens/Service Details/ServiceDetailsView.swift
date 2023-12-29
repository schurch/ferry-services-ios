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
    
    var showDisruptionInfo: (String) -> Void
    var showTimetable: (Service, URL) -> Void
    var showMap: (Service) -> Void
    
    init(
        serviceID: Int,
        service: Service?,
        showDisruptionInfo: @escaping (String) -> Void,
        showTimetable: @escaping (Service, URL) -> Void,
        showMap: @escaping (Service) -> Void
    ) {
        _model = StateObject(
            wrappedValue: ServiceDetailModel(
                serviceID: serviceID,
                service: service
            )
        )
        self.showDisruptionInfo = showDisruptionInfo
        self.showTimetable = showTimetable
        self.showMap = showMap
    }
    
    var body: some View {
        if let service = model.service {
            List {
                Section {
                    VStack(spacing: 0) {
                        if !model.annotations.isEmpty {
                            Map(
                                mapRect: $model.mapRect,
                                interactionModes: [],
                                annotationItems: model.annotations
                            ) { annotation in
                                MapAnnotation(
                                    coordinate: annotation.coordinate
                                ) {
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
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    
                    if model.registeredForNotifications {
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
                }
                
                ForEach(service.locations.sorted(by: { $0.name < $1.name })) { location in
                    Section {
                        LocationInformation(location: location)
                    }
                    .padding(.top, 8)
                    .listRowSeparator(.hidden)
                }
                
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
                    .frame(maxWidth: .infinity)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .listRowSeparator(.hidden)
                    
                    let badStatuses: [Service.Status] = [.cancelled, .disrupted, .unknown]
                    if badStatuses.contains(service.status) {
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.colorAmber)
                            Text("Sailings may not be operating to the scheduled departure times. Please check the disruption information or the ferry service operator website for more details.")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.systemGray))
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowSeparator(.hidden)
                    }
                }
                
                ForEach(service.locations.sorted(by: { $0.scheduledDepartures?.first?.departure ?? Date() < $1.scheduledDepartures?.first?.departure ?? Date() })) { location in
                    ForEach(location.groupedScheduledDepartures, id: \.self.first?.destination.id) { departures in
                        Section {
                            ForEach(departures) { departureInfo in
                                HStack {
                                    Text(
                                        departureInfo
                                            .departure
                                            .formatted(Date.timeFormatStyle)
                                    )
                                    Spacer()
                                    Text(
                                        departureInfo
                                            .arrival
                                            .formatted(Date.timeFormatStyle)
                                    )
                                }
                                .foregroundColor(departureInfo.departure > Date() ? Color(UIColor.label) : Color(UIColor.systemGray2))
                            }
                        } header: {
                            HStack {
                                Text(location.name)
                                Spacer()
                                Image(systemName: "arrow.right")
                                Spacer()
                                Text(departures.first!.destination.name)
                            }
                        }
                    }
                }
                
                if let serviceOperator = service.operator {
                    Section {
                        ServiceOperator(serviceOperator: serviceOperator)
                            .padding([.bottom], 5)
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
                Task {
                    await model.fetchLatestService()
                }
            }
        } else {
            Text("Loading...")
                .task {
                    await model.fetchLatestService()
                }
        }
    }
    
}

private struct LocationInformation: View {
    private static let animationOffsets = Bool.random() ? [15, 0, -15, 0, 0] : [-15, 0, 15, 0, 0]

    private let location: Service.Location
    
    @State private var animationRotationOffset = 0
    @State private var currentAnimationOffsetIndex = 0
    
    private let animationInterval: Double
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init(location: Service.Location) {
        self.location = location
        self.animationInterval = Double.random(in: 1...2)
        self.timer = Timer.publish(every: animationInterval, on: .main, in: .common).autoconnect()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(location.name)
                .font(.title3)
            
            if let nextDeparture = location.nextDeparture {
                HStack(alignment: .center) {
                    Image(systemName: "clock")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.thin)
                        .frame(height: 25)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .padding([.leading, .trailing], 12)
                        .padding([.top, .bottom], 8)
                    VStack(alignment: .leading) {
                        Text("Next depature")
                            .font(.subheadline)
                        Text("\(nextDeparture.departure.formatted(Date.timeFormatStyle)) to \(nextDeparture.destination.name)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
                
                Divider()
                    .padding(.leading, 55)
            }
            
            if let weather = location.weather {
                HStack(alignment: .center) {
                    Image(weather.icon)
                        .renderingMode(.template)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    VStack(alignment: .leading) {
                        Text("Weather")
                            .font(.subheadline)
                        Text("\(weather.temperatureCelsius)ºC • \(weather.description)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
                
                Divider()
                    .padding(.leading, 55)
                
                HStack(alignment: .center) {
                    Image("Wind")
                        .renderingMode(.template)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .rotationEffect(
                            .degrees(Double(weather.windDirection + animationRotationOffset + 180))
                        )
                        .animation(.linear(duration: animationInterval), value: animationRotationOffset)
                        .onReceive(timer) { input in
                            animationRotationOffset = LocationInformation.animationOffsets[currentAnimationOffsetIndex % LocationInformation.animationOffsets.count]
                            currentAnimationOffsetIndex += 1
                        }
                    VStack(alignment: .leading) {
                        Text("Wind")
                            .font(.subheadline)
                        Text("\(weather.windSpeedMph) MPH • \(weather.windDirectionCardinal)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 0.5)
        )
    }
}

private struct ServiceOperator: View {
    
    let serviceOperator: Service.ServiceOperator
    @Environment(\.openURL) var openURL
    @State private var showingPhoneAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let imageName = serviceOperator.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                }
                
                Text(serviceOperator.name)
                    .font(.title2)
            }
            
            VStack(spacing: 5) {
                HStack {
                    Button("PHONE") {
                        showingPhoneAlert = true
                    }
                    .disabled(serviceOperator.localNumber == nil && serviceOperator.internationalNumber == nil)
                    .confirmationDialog("Phone", isPresented: $showingPhoneAlert) {
                        if let local = serviceOperator.localNumber {
                            let localFormatted = local.replacingOccurrences(of: " ", with: "-")
                            Button(local) {
                                openURL(URL(string: "tel://\(localFormatted)")!)
                            }
                        }
                        
                        if let international = serviceOperator.internationalNumber {
                            let internationalFormatted = international.replacingOccurrences(of: " ", with: "-")
                            Button(international) {
                                openURL(URL(string: "tel://\(internationalFormatted)")!)
                            }
                        }
                    }
                    
                    Button("WEBSITE") {
                        openURL(URL(string: serviceOperator.website!)!)
                    }
                    .disabled(serviceOperator.website == nil)
                }
                
                HStack {
                    Button("EMAIL") {
                        openURL(URL(string: "mailto:\(serviceOperator.email!)")!)
                    }
                    .disabled(serviceOperator.email == nil)
                    
                    Button("TWITTER") {
                        openURL(URL(string: serviceOperator.x!)!)
                    }
                    .disabled(serviceOperator.x == nil)
                }
                
                HStack {
                    Button("FACEBOOK") {
                        openURL(URL(string: serviceOperator.facebook!)!)
                    }
                    .disabled(serviceOperator.facebook == nil)
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                        .padding()

                }
            }
            .buttonStyle(.standard)
        }
    }
    
}

private struct DisruptionInfoView: View {
    let service: Service
    
    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(service.status.statusColor)
                .frame(width: 25, height: 25, alignment: .center)
            Text(service.disruptionText)
            
            if !(service.additionalInfo ?? "").isEmpty {
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
            }
        }
        .padding([.top, .bottom], 5)
    }
}

extension ServiceDetailsView {
    
    // Used for bridging to the existing UIKit code
    static func createViewController(
        serviceID: Int,
        service: Service?,
        navigationController: UINavigationController
    ) -> UIViewController {
        let serviceDetailView = ServiceDetailsView(
            serviceID: serviceID,
            service: service,
            showDisruptionInfo: { html in
                let disruptionViewController = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "WebInformation") as! WebInformationViewController
                disruptionViewController.html = html
                
                navigationController.pushViewController(disruptionViewController, animated: true)
            },
            showTimetable: { (service, timetableURL) in
                let timetableViewController = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "TimetablePreview") as! TimetablePreviewViewController
                timetableViewController.service = service
                timetableViewController.url = timetableURL
                
                navigationController.pushViewController(timetableViewController, animated: true)
            },
            showMap: { service in
                let mapViewController = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
                mapViewController.service = service
                
                navigationController.pushViewController(mapViewController, animated: true)
            }
        )
        
        let viewController = UIHostingController(rootView: serviceDetailView)
        viewController.title = service?.area ?? NSLocalizedString("Service", comment: "")
        viewController.navigationItem.largeTitleDisplayMode = .never
        
        return viewController
    }
    
}

private extension Service.Location {
    
    // Grouped on destination
    var groupedScheduledDepartures: [[Service.Location.ScheduledDeparture]] {
        guard let scheduledDepartures else { return [] }
        let groups = Dictionary(grouping: scheduledDepartures, by: { $0.destination.id })
        return Array(groups.values)
            .sorted(by: { $0.first?.departure ?? Date() < $1.first?.departure ?? Date() })
    }
    
}

extension ButtonStyle where Self == StandardButtonStyle {
    static var standard: StandardButtonStyle { StandardButtonStyle() }
}

struct StandardButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity, minHeight: 33)
            .foregroundStyle(isEnabled ? Color(UIColor.label) : Color(UIColor.systemGray2))
            .background(Color(UIColor.systemGray5))
            .cornerRadius(6)
            
    }
}
