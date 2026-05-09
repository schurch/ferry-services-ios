import SwiftUI

struct ServiceDetailsStatusSectionView: View {
    let service: Service
    let timetableDocumentCount: Int
    let hasLoadedNotificationsAuthorization: Bool
    let isEnabledForNotifications: Bool
    let isRegisteredForNotifications: Bool
    let loadingSubscribed: Bool
    @Binding var subscribed: Bool
    let updateSubscribed: (Bool) -> Void
    let showTimetableDocuments: () -> Void
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

            if timetableDocumentCount > 0 {
                Button {
                    showTimetableDocuments()
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .frame(width: 25, height: 25)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("View timetables")
                            Text(timetableSummaryText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                }
                .foregroundStyle(.primary)
            }

            if hasLoadedNotificationsAuthorization && !isEnabledForNotifications {
                Button {
                    openNotificationSettings()
                } label: {
                    NavigationLink("Enable notifications to subscribe", destination: EmptyView())
                }
                .listRowSeparator(.hidden)
            } else if hasLoadedNotificationsAuthorization && !isRegisteredForNotifications {
                HStack {
                    Text("Subscribe to updates")
                    Spacer()
                    ProgressView()
                        .id(UUID())
                        .padding(.trailing, 12)
                }
                .listRowSeparator(.hidden)
            } else if hasLoadedNotificationsAuthorization && isRegisteredForNotifications {
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
                        .onChange(of: subscribed) { _, value in
                            updateSubscribed(value)
                        }
                        .listRowSeparator(.hidden)
                }
            }
        }
    }

    private var timetableSummaryText: String {
        timetableDocumentCount == 1 ? "1 document" : "\(timetableDocumentCount) documents"
    }

}
