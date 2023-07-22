//
//  ServiceDetailsView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 21/07/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI
import MapKit

struct ServiceDetailsView: View {
    
    @StateObject private var model: ServiceDetailModel
    
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
                        Map(
                            mapRect: $model.mapRect,
                            interactionModes: [],
                            annotationItems: model.annotations
                        ) { annotation in
                            MapAnnotation(
                                coordinate: annotation.coordinate
                            ) {
                                switch annotation.type {
                                case .location:
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.red)
                                case .vessel(let course):
                                    Image("ferry")
                                        .rotationEffect(.degrees(course))
                                }
                            }
                        }
                        .frame(height: 200)
                        .onTapGesture {
                            showMap(service)
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
                    
                    if model.loadingSubscribed {
                        HStack {
                            Text("Subscribe to updates")
                            Spacer()
                            // Progress view sometimes wouldn't show again so give it a unique ID each time
                            ProgressView().id(UUID())
                        }
                    } else {
                        Toggle("Subscribe to updates", isOn: $model.subscribed)
                    }
                }
                
                if model.timetables.count > 0 {
                    Section("Timetables") {
                        ForEach(model.timetables) { timetable in
                            Button {
                                showTimetable(
                                    service,
                                    timetable.fileLocation
                                )
                            } label: {
                                HStack {
                                    Text(timetable.text)
                                    Spacer()
                                    Image(systemName: "chevron.forward")
                                        .font(Font.system(.caption).weight(.bold))
                                        .foregroundColor(Color(UIColor.tertiaryLabel))
                                    
                                }
                            }
                        }
                    }
                }
                
                ForEach(service.locations) { location in
                    if let weather = location.weather {
                        Section("\(location.name) weather") {
                            WeatherView(weather: weather)
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        }
                    }
                    
                    if let scheduledDepartures = location.scheduledDepartures,
                       scheduledDepartures.count > 0
                    {
                        Section {
                            ForEach(scheduledDepartures) { departureInfo in
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
                                Text("\(location.name) departure")
                                Spacer()
                                Image(systemName: "arrow.right")
                                Spacer()
                                Text("\(scheduledDepartures.first!.destination.name) arrival")
                            }
                        } footer: {
                            let badStatuses: [Service.Status] = [.cancelled, .disrupted, .unknown]
                            if badStatuses.contains(service.status) {
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(Color("Amber"))
                                    Text("Sailings may not be operating to the scheduled departure times. Please check the disruption information or the ferry service operator website.")
                                        .font(.footnote)
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets())
            .task {
                await model.fetchLatestService()
            }
        } else {
            Text("Loading...")
                .task {
                    await model.fetchLatestService()
                }
        }
    }
    
}

private struct DisruptionInfoView: View {
    let service: Service
    
    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(service.statusColor)
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

private struct WeatherView: View {
    var weather: Service.Location.Weather
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                HStack {
                    Image(weather.icon)
                    Text("\(weather.temperatureCelsius)°C")
                        .font(.body)
                }
                Text(weather.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding([.top, .bottom], 4)
            
            Color(uiColor: UIColor.separator)
                .frame(width: 0.5)
                .padding(0)
            
            VStack(spacing: 0) {
                HStack {
                    Image("Wind")
                        .rotationEffect(.degrees(Double(weather.windDirection + 180)))
                    Text("\(weather.windSpeedMph) MPH")
                        .font(.body)
                }
                Text(weather.windDirectionCardinal)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding([.top, .bottom], 4)
        }
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
        viewController.title = service?.area ?? "Service"
        viewController.navigationItem.largeTitleDisplayMode = .never
        
        return viewController
    }
    
}

extension Service {
    var statusColor: Color {
        switch status {
        case .unknown: return Color("Grey")
        case .normal: return Color("Green")
        case .disrupted: return Color("Amber")
        case .cancelled: return Color("Red")
        }
    }
    
    var disruptionText: String {
        switch status {
        case .normal: return "There are currently no disruptions with this service"
        case .disrupted: return "There are disruptions with this service"
        case .cancelled: return "Sailings have been cancelled for this service"
        case .unknown: return ""
        }
    }
}
