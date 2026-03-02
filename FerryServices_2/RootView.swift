import SwiftUI

struct RootView: View {
    @ObservedObject var navigationState: AppNavigationState
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $navigationState.path) {
            ServicesView { service in
                navigationState.path.append(.serviceDetails(service.serviceId))
            }
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheetView()
            }
            .navigationDestination(for: AppNavigationState.Destination.self) { destination in
                switch destination {
                case .serviceDetails(let serviceID):
                    ServiceDetailsView(
                        serviceID: serviceID,
                        service: Service.defaultServices.first(where: { $0.serviceId == serviceID }),
                        showDisruptionInfo: { html in
                            navigationState.pushWebInfo(html: html)
                        },
                        showMap: { service in
                            navigationState.pushMap(service: service)
                        }
                    )
                case .map(let id):
                    if let service = navigationState.mapService(for: id) {
                        MapView(service: service)
                    }
                case .webInfo(let id):
                    if let html = navigationState.webInfo(for: id) {
                        WebInformationView(html: html)
                    }
                }
            }
            .alert("Alert", isPresented: alertIsPresentedBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(navigationState.alertMessage ?? "")
            }
        }
    }

    private var alertIsPresentedBinding: Binding<Bool> {
        Binding(
            get: { navigationState.alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    navigationState.alertMessage = nil
                }
            }
        )
    }
}

private struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsView()
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
