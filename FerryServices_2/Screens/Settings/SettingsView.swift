//
//  SettingsView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/06/2024.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import SwiftUI

enum SettingsNotificationsState {
    case loading
    case authorized(isOn: Bool)
    case notAuthorized
    case error
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var notificationsState: SettingsNotificationsState = .loading
    
    var body: some View {
        let version = "Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber)"
        List {
            Section {
                switch notificationsState {
                case .loading:
                    HStack {
                        Text("Enabled")
                        Spacer()
                        // Progress view sometimes wouldn't show again so give it a unique ID each time
                        ProgressView()
                            .id(UUID())
                            .padding(.trailing, 12)
                    }
                    
                case .authorized(let isOn):
                    Toggle("Enabled",
                           isOn: Binding(
                            get: { isOn },
                            set: { newIsOn in
                                Task {
                                    notificationsState = .loading

                                    do {
                                        try await APIClient.updatePushEnabledStatus(
                                            installationID: Installation.id,
                                            isEnabled: newIsOn
                                        )
                                        notificationsState = .authorized(isOn: newIsOn)
                                    } catch {
                                        notificationsState = .authorized(isOn: !newIsOn)
                                    }
                                }
                            })
                    )
                    
                case .notAuthorized:
                    Button("Enable notifications in Settings") {
                        let url = URL(string: UIApplication.openNotificationSettingsURLString)!
                        openURL(url)
                    }
                    
                case .error:
                    Text("An error occured fetching the notification status")
                        .foregroundStyle(Color.gray)
                    
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
        let areNotificationsAuthorized = await Self.areNotificationsAuthorized()
        guard areNotificationsAuthorized else {
            notificationsState = .notAuthorized
            return
        }
        
        do {
            let enabled = try await APIClient.getPushEnabledStatus(
                installationID: Installation.id
            )
            notificationsState = .authorized(isOn: enabled)
        } catch {
            notificationsState = .error
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
