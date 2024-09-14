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
                            let url = URL(string: UIApplication.openNotificationSettingsURLString)!
                            openURL(url)
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
                        
                        let moreInfoURL = URL(string: "ferryservices://more-info")!
                        
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
                                if url == moreInfoURL {
                                    showDisruptionInfo(service.additionalInfo!)
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
                                Text(location.name)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .accessibilityLabel("to")
                                Spacer()
                                Text(departures.first!.destination.name)
                            }
                            .accessibilityElement(children: .combine)
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
            .onAppear {
                Task { await model.fetchLatestService() }
                Task { await model.checkIsEnabledForNotifications() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task { await model.fetchLatestService() }
                Task { await model.checkIsEnabledForNotifications() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .registeredForNotifications), perform: { _ in
                model.checkIsRegisteredForNotifications()
            })
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
        let textVerticalSpacing: CGFloat = 4
        
        VStack(alignment: .leading) {
            Text(location.name)
                .font(.title3)
            
            if let nextDeparture = location.nextDeparture {
                HStack(alignment: .center) {
                    Image(systemName: "ferry")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.thin)
                        .frame(width: 20)
                        .padding([.leading, .trailing], 12)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Next ferry departure")
                            .font(.subheadline)
                        Text("\(nextDeparture.departure.formatted(Date.timeFormatStyle)) to \(nextDeparture.destination.name)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    .accessibilityElement(children: .combine)
                }
                
                Divider()
                    .padding(.leading, 55)
            }
            
            if let railDeparture = location.nextRailDeparture {
                HStack(alignment: .center) {
                    Image(systemName: "lightrail")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.thin)
                        .frame(width: 18)
                        .padding([.leading, .trailing], 14)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Next rail departure")
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(railDeparture.departure.formatted(Date.timeFormatStyle)) to \(railDeparture.to)")
                                .font(.subheadline)
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                            HStack(spacing: 4) {
                                Text(railDeparture.departureInfo)
                                    .foregroundStyle(railDeparture.isCancelled ? Color(UIColor.colorRed) : Color(UIColor.secondaryLabel))
                                if let platform = railDeparture.platform {
                                    Text("•")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .accessibilityHidden(true)
                                    Text("Platform \(platform)")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                
                Divider()
                    .padding(.leading, 55)
            }
            
            if let weather = location.weather {
                HStack(alignment: .center) {
                    Image(weather.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding([.leading, .trailing], 6)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Weather")
                            .font(.subheadline)
                        Text("\(weather.temperatureCelsius)ºC • \(weather.description)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .accessibilityLabel("\(weather.temperatureCelsius)ºC, \(weather.description)")
                    }
                    .accessibilityElement(children: .combine)
                }
                
                Divider()
                    .padding(.leading, 55)
                
                HStack(alignment: .center) {
                    Image("Wind")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding([.leading, .trailing], 6)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .rotationEffect(
                            .degrees(Double(weather.windDirection + animationRotationOffset + 180))
                        )
                        .animation(.linear(duration: animationInterval), value: animationRotationOffset)
                        .onReceive(timer) { input in
                            animationRotationOffset = LocationInformation.animationOffsets[currentAnimationOffsetIndex % LocationInformation.animationOffsets.count]
                            currentAnimationOffsetIndex += 1
                        }
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Wind")
                            .font(.subheadline)
                        Text("\(weather.windSpeedMph) MPH • \(weather.windDirectionCardinal)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .accessibilityLabel("\(weather.windSpeedMph) MPH, \(weather.windDirectionCardinal)")
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
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
                        .accessibilityHidden(true)
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
            DisruptionIndicator(status: service.status)
            
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
