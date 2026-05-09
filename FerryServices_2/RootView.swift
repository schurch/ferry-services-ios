import SwiftUI

struct RootView: View {
    var navigationState: AppNavigationState
    @State private var showingSettings = false

    var body: some View {
        @Bindable var navigationState = navigationState
        
        TabView(selection: $navigationState.selectedTab) {
            NavigationStack(path: $navigationState.servicesPath) {
                ServicesView { service in
                    navigationState.pushServiceDetails(service: service)
                }
                .navigationTitle("Services")
                .toolbar {
                    settingsToolbarItem
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
                                },
                                showTimetableDocuments: { serviceID, title in
                                    navigationState.pushServiceTimetableDocuments(
                                        serviceID: serviceID,
                                        title: title
                                    )
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
                    case .timetableDocuments(let id):
                        if let payload = navigationState.timetableDocuments(for: id) {
                            TimetableDocumentsView(
                                serviceID: payload.serviceID,
                                title: payload.title
                            )
                        } else {
                            Text("Timetables unavailable")
                        }
                    }
                }
            }
            .tabItem {
                Label("Services", systemImage: "ferry")
            }
            .tag(AppNavigationState.Tab.services)

            NavigationStack(path: $navigationState.timetablesPath) {
                TimetableDocumentsView()
                    .navigationDestination(for: AppNavigationState.Destination.self) { destination in
                        switch destination {
                        case .timetableDocuments(let id):
                            if let payload = navigationState.timetableDocuments(for: id) {
                                TimetableDocumentsView(
                                    serviceID: payload.serviceID,
                                    title: payload.title
                                )
                            } else {
                                Text("Timetables unavailable")
                            }
                        case .serviceDetails, .map, .webInfo:
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Timetables", systemImage: "document")
            }
            .tag(AppNavigationState.Tab.timetables)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheetView()
        }
        .alert("Alert", isPresented: alertIsPresentedBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(navigationState.alertMessage ?? "")
        }
    }

    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
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
