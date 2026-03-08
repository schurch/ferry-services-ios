import MapKit
import SwiftUI

struct ServiceDetailsHeaderSectionView: View {
    let service: Service
    let annotations: [Annotation]
    let mapPosition: Binding<MapCameraPosition>
    let showMap: (Service) -> Void

    var body: some View {
        Section {
            VStack(spacing: 0) {
                if !annotations.isEmpty {
                    Map(
                        position: mapPosition,
                        interactionModes: []
                    ) {
                        ForEach(annotations) { annotation in
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
    }
}
