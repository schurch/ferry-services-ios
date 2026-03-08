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
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            Section {
                switch viewModel.notificationsState {
                case .loading:
                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        // Progress view sometimes wouldn't show again so give it a unique ID each time
                        ProgressView()
                            .id(UUID())
                            .padding(.trailing, 12)
                    }
                    
                case .authorized(let isOn):
                    Toggle("Push Notifications",
                           isOn: Binding(
                            get: { isOn },
                            set: { newIsOn in
                                viewModel.toggleNotifications(isEnabled: newIsOn)
                            })
                    )
                    
                case .notAuthorized:
                    Button("Enable notifications in Settings") {
                        if let url = viewModel.notificationSettingsURL {
                            openURL(url)
                        }
                    }
                    
                case .error:
                    Text("An error occured fetching the notification status")
                        .foregroundStyle(Color.gray)
                    
                }
            }
            
            Section {
                Button("Email") {
                    if let url = viewModel.supportEmailURL() {
                        openURL(url)
                    }
                }
                
                Button("Rate on App Store") {
                    if let url = viewModel.appStoreURL {
                        openURL(url)
                    }
                }
            } header: {
                Text("Contact")
            }
            
            Section {
                Text(viewModel.versionText)
            } footer: {
                Text("Hi, I'm Stefan. Thanks for using the Scottish Ferries App. Although I now live overseas, I grew up on the Isle of Arran so can appreciate how vital the ferry services are. If you have any questions or issues please feel free to email me, or if you find the app useful you can also leave a review on the App Store.")
                    .padding(.top, 10)
                    .font(.callout)
            }
        }
        .task {
            await viewModel.refreshNotificationState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await viewModel.refreshNotificationState() }
        }
    }
}

#Preview {
    SettingsView()
}
