import SwiftUI

struct RootView: View {
    var navigationState: AppNavigationState
    @State private var showingSettings = false

    var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack(path: $navigationState.path) {
            ServicesView { service in
                navigationState.pushServiceDetails(service: service)
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
                case .serviceDetails(let id):
                    if let details = navigationState.serviceDetails(for: id) {
                        ServiceDetailsView(
                            serviceID: details.serviceID,
                            service: details.seedService,
                            showDisruptionInfo: { html in
                                navigationState.pushWebInfo(html: html)
                            },
                            showMap: { service in
                                navigationState.pushMap(service: service)
                            }
                        )
                    } else {
                        Text("Service details unavailable")
                    }
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
