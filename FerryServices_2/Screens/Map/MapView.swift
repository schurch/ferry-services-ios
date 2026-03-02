//
//  MapViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 25/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: View {
    let service: Service

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapBounds: MapCameraBounds?
    @State private var selectedVessel: Vessel?

    private struct MapItem: Identifiable {
        enum Kind {
            case vessel(Vessel)
            case location
        }

        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
        let kind: Kind

        var mapPoint: MKMapPoint {
            MKMapPoint(coordinate)
        }
    }

    private var locationItems: [MapItem] {
        service.locations.map { location in
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                title: location.name,
                kind: .location
            )
        }
    }

    private var vesselItems: [MapItem] {
        (service.vessels ?? []).map { vessel in
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: vessel.latitude, longitude: vessel.longitude),
                title: vessel.name,
                kind: .vessel(vessel)
            )
        }
    }

    private var mapItems: [MapItem] {
        locationItems + vesselItems
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(
                position: $cameraPosition,
                bounds: mapBounds,
                interactionModes: [.all],
                content: {
                    ForEach(mapItems) { item in
                        MapKit.Annotation(coordinate: item.coordinate, anchor: .center) {
                            annotationView(for: item)
                        } label: {
                            Text(item.title)
                        }
                    }
                }
            )
            .onTapGesture {
                selectedVessel = nil
            }

            if let vessel = selectedVessel {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vessel.name)
                        .font(.headline)
                    Text("Speed: \(speedText(for: vessel))")
                        .font(.subheadline)
                    Text("Last received: \(relativeLastReceivedText(for: vessel.lastReceived))")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(12)
            }
        }
        .navigationTitle(service.route)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateMapRegion()
        }
    }

    @ViewBuilder
    private func annotationView(for item: MapItem) -> some View {
        switch item.kind {
        case .vessel(let vessel):
            Image("ferry")
                .rotationEffect(.degrees(vessel.course ?? 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedVessel = vessel
                }
        case .location:
            Image("map-annotation")
                .resizable()
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedVessel = nil
                }
        }
    }

    private func speedText(for vessel: Vessel) -> String {
        guard let speed = vessel.speed else {
            return "Unknown"
        }
        return "\(speed.formatted(.number.precision(.fractionLength(1)))) kn"
    }

    private func relativeLastReceivedText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func updateMapRegion() {
        let focusItems = locationItems.isEmpty ? mapItems : locationItems
        let points = focusItems.map(\.mapPoint)

        guard let firstPoint = points.first else { return }

        var minX = firstPoint.x
        var minY = firstPoint.y
        var maxX = firstPoint.x
        var maxY = firstPoint.y

        for point in points.dropFirst() {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        var rect = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        if rect.size.width == 0 || rect.size.height == 0 {
            rect = rect.insetBy(dx: -1_000, dy: -1_000)
        } else {
            let xInset = -(rect.size.width * 0.2)
            let yInset = -(rect.size.height * 0.2)
            rect = rect.insetBy(dx: xInset, dy: yInset)
        }

        mapBounds = MapCameraBounds(centerCoordinateBounds: rect)
        cameraPosition = .rect(rect)
    }
}
