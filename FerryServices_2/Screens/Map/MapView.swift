//
//  MapViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import SwiftUI
import MapKit

struct UIKitServiceMapView: UIViewRepresentable {
    let service: Service
    var interactionEnabled: Bool
    var fitToLocationsOnly: Bool = true
    private static let departureTimeFormatStyle: Date.FormatStyle = {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = TimeZone(secondsFromGMT: 0)!
        return style
    }()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        mapView.isScrollEnabled = interactionEnabled
        mapView.isZoomEnabled = interactionEnabled
        mapView.isRotateEnabled = interactionEnabled
        mapView.isPitchEnabled = interactionEnabled
        mapView.isUserInteractionEnabled = interactionEnabled

        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(context.coordinator.annotations(for: service))

        let locationCoordinates = service.locations.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let vesselCoordinates = (service.vessels ?? []).map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let focusCoordinates = if fitToLocationsOnly, !locationCoordinates.isEmpty {
            locationCoordinates
        } else {
            locationCoordinates + vesselCoordinates
        }

        let mapRect = MapViewHelpers.calculateMapRect(forCoordinates: focusCoordinates)
        if !mapRect.isNull && !mapRect.isEmpty {
            mapView.setVisibleMapRect(
                mapRect,
                edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
                animated: false
            )
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UIKitServiceMapView

        init(_ parent: UIKitServiceMapView) {
            self.parent = parent
        }

        func annotations(for service: Service) -> [ServiceAnnotation] {
            let locationAnnotations: [ServiceAnnotation] = service.locations.map { location in
                let subtitle: String? = {
                    guard let nextDeparture = location.nextDeparture else { return nil }
                    return "Next departure: \(nextDeparture.departure.formatted(UIKitServiceMapView.departureTimeFormatStyle)) to \(nextDeparture.destination.name)"
                }()

                return ServiceAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    title: location.name,
                    subtitle: subtitle,
                    kind: .location(location)
                )
            }

            let vesselAnnotations: [ServiceAnnotation] = (service.vessels ?? []).map { vessel in
                let subtitle: String = {
                    if let speed = vessel.speed {
                        return "\(speed.formatted(.number.precision(.fractionLength(1)))) kn"
                    } else {
                        return "Speed unknown"
                    }
                }()

                return ServiceAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: vessel.latitude,
                        longitude: vessel.longitude
                    ),
                    title: vessel.name,
                    subtitle: subtitle,
                    kind: .vessel(vessel)
                )
            }

            return locationAnnotations + vesselAnnotations
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? ServiceAnnotation else { return nil }

            let view: MKAnnotationView
            switch annotation.kind {
            case .location:
                let identifier = "location"
                view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.image = UIImage(named: "map-annotation")
                view.transform = .identity
                view.displayPriority = .required
                view.zPriority = .min
            case .vessel(let vessel):
                let identifier = "vessel"
                view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.transform = .identity
                view.image = rotatedFerryImage(course: vessel.course)
                view.displayPriority = .required
                view.zPriority = .max
            }

            view.annotation = annotation
            view.canShowCallout = true
            view.detailCalloutAccessoryView = detailCalloutView(for: annotation)
            return view
        }
        
        private func rotatedFerryImage(course: Double?) -> UIImage? {
            guard let image = UIImage(named: "ferry"), let course else { return UIImage(named: "ferry") }
            
            let angle = CGFloat(course * .pi / 180)
            let renderer = UIGraphicsImageRenderer(size: image.size)
            return renderer.image { context in
                context.cgContext.translateBy(x: image.size.width / 2, y: image.size.height / 2)
                context.cgContext.rotate(by: angle)
                image.draw(
                    in: CGRect(
                        x: -image.size.width / 2,
                        y: -image.size.height / 2,
                        width: image.size.width,
                        height: image.size.height
                    )
                )
            }
        }

        private func detailCalloutView(for annotation: ServiceAnnotation) -> UIView? {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel

            switch annotation.kind {
            case .vessel(let vessel):
                let speedText: String = if let speed = vessel.speed {
                    "\(speed.formatted(.number.precision(.fractionLength(1)))) knots"
                } else {
                    "Unknown"
                }
                let relativeDateText = RelativeDateTimeFormatter().localizedString(
                    for: vessel.lastReceived,
                    relativeTo: Date()
                )
                label.text = "\(speedText) • \(relativeDateText)"
            case .location(let location):
                if let nextDeparture = location.nextDeparture {
                    label.text = "Next departure: \(nextDeparture.departure.formatted(UIKitServiceMapView.departureTimeFormatStyle)) to \(nextDeparture.destination.name)"
                } else {
                    label.text = "No upcoming departure info"
                }
            }

            return label
        }
    }

    final class ServiceAnnotation: NSObject, MKAnnotation {
        enum Kind {
            case location(Service.Location)
            case vessel(Vessel)
        }

        let coordinate: CLLocationCoordinate2D
        let title: String?
        let subtitle: String?
        let kind: Kind

        init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, kind: Kind) {
            self.coordinate = coordinate
            self.title = title
            self.subtitle = subtitle
            self.kind = kind
        }
    }
}

struct MapView: View {
    @State private var viewModel: MapViewModel

    init(service: Service) {
        _viewModel = State(initialValue: MapViewModel(service: service))
    }

    var body: some View {
        UIKitServiceMapView(
            service: viewModel.service,
            interactionEnabled: true,
            fitToLocationsOnly: true
        )
        .ignoresSafeArea()
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
