//
//  SettingsView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/06/2024.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var areNotificationsAuthorized = true
    @State private var loadingNotifications = true
    @State private var pushNotificationsEnabled = false
    @State private var errorLoadingNotfications = false
    
    var body: some View {
        let version = "Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber)"
        List {
            Section {
                if errorLoadingNotfications {
                    Text("An error occured fetching the notification status")
                        .foregroundStyle(Color.gray)
                } else if loadingNotifications {
                    HStack {
                        Text("Enabled")
                        Spacer()
                        // Progress view sometimes wouldn't show again so give it a unique ID each time
                        ProgressView()
                            .id(UUID())
                            .padding(.trailing, 12)
                    }
                } else if !areNotificationsAuthorized {
                    Button {
                        let url = URL(string: UIApplication.openNotificationSettingsURLString)!
                        openURL(url)
                    } label: {
                        NavigationLink("Enable notifications to in Settings", destination: EmptyView())
                    }
                } else {
                    Toggle("Enabled",
                           isOn: Binding(
                            get: { pushNotificationsEnabled },
                            set: { isOn in
                                Task {
                                    loadingNotifications = true

                                    do {
                                        try await APIClient.updatePushEnabledStatus(
                                            installationID: Installation.id,
                                            isEnabled: isOn
                                        )
                                        pushNotificationsEnabled = isOn
                                    } catch {
                                        pushNotificationsEnabled = !isOn
                                    }
                                    
                                    loadingNotifications = false
                                }
                            })
                    )
                }
            } header: {
                Text("Push Notifications")
            }
            
            Section {
                Button("Email") {
                    let url = URL(string: "mailto:stefan.church@gmail.com?subject=Scottish Ferries App (\(version))")!
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                
                Link(
                    "Rate on App Store",
                    destination: URL(string: "https://apps.apple.com/app/id861271891")!
                )
            } header: {
                Text("Contact")
            }
            
            Section {
                Text(version)
            } footer: {
                Text("Hi, I'm Stefan. Thanks for using the Scottish Ferries App. Although I now live overseas, I grew up on the Isle of Arran so can appreciate how vital the ferry services are. If you have any questions or issues please feel free to email me, or if you find the app useful you can also leave a review on the App Store.")
                    .padding(.top, 10)
                    .font(.callout)
            }
        }
        .background(.colorBackground)
        .scrollContentBackground(.hidden)
        .task {
            await checkNotificationState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await checkNotificationState() }
        }
    }
    
    @MainActor
    private func checkNotificationState() async {
        areNotificationsAuthorized = await Self.areNotificationsAuthorized()
        guard areNotificationsAuthorized else {
            loadingNotifications = false
            return
        }
        
        do {
            pushNotificationsEnabled = try await APIClient.getPushEnabledStatus(
                installationID: Installation.id
            )
            loadingNotifications = false
        } catch {
            errorLoadingNotfications = true
        }
    }
    
    static func areNotificationsAuthorized() async -> Bool {
        nonisolated(unsafe) let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

private extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}

#Preview {
    SettingsView()
}
