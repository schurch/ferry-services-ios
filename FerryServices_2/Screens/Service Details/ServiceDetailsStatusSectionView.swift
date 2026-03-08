import SwiftUI

struct ServiceDetailsStatusSectionView: View {
    let service: Service
    let isEnabledForNotifications: Bool
    let isRegisteredForNotifications: Bool
    let loadingSubscribed: Bool
    @Binding var subscribed: Bool
    let updateSubscribed: (Bool) -> Void
    let openNotificationSettings: () -> Void
    let showDisruptionInfo: (String) -> Void

    var body: some View {
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

            if isEnabledForNotifications {
                if isRegisteredForNotifications {
                    if loadingSubscribed {
                        HStack {
                            Text("Subscribe to updates")
                            Spacer()
                            ProgressView()
                                .id(UUID())
                                .padding(.trailing, 12)
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        Toggle("Subscribe to updates", isOn: $subscribed)
                            .onChange(of: subscribed) { value in
                                updateSubscribed(value)
                            }
                            .listRowSeparator(.hidden)
                    }
                }
            } else {
                Button {
                    openNotificationSettings()
                } label: {
                    NavigationLink("Enable notifications to subscribe", destination: EmptyView())
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}
