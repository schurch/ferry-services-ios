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
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            Section {
                switch viewModel.notificationsState {
                case .loading:
                    HStack {
                        Text(SettingsViewModel.Copy.pushNotificationsTitle)
                        Spacer()
                        // Progress view sometimes wouldn't show again so give it a unique ID each time
                        ProgressView()
                            .id(UUID())
                            .padding(.trailing, 12)
                    }
                    
                case .authorized(let isOn):
                    Toggle(SettingsViewModel.Copy.pushNotificationsTitle,
                           isOn: Binding(
                            get: { isOn },
                            set: { newIsOn in
                                viewModel.toggleNotifications(isEnabled: newIsOn)
                            })
                    )
                    
                case .notAuthorized:
                    Button(SettingsViewModel.Copy.enableNotificationsInSettings) {
                        if let url = viewModel.notificationSettingsURL {
                            openURL(url)
                        }
                    }
                    
                case .error:
                    Text(SettingsViewModel.Copy.notificationsStatusError)
                        .foregroundStyle(Color.gray)
                    
                }
            }
            
            Section {
                Button(SettingsViewModel.Copy.emailButtonTitle) {
                    if let url = viewModel.supportEmailURL() {
                        openURL(url)
                    }
                }
                
                Button(SettingsViewModel.Copy.rateButtonTitle) {
                    if let url = viewModel.appStoreURL {
                        openURL(url)
                    }
                }
            } header: {
                Text(SettingsViewModel.Copy.contactSectionTitle)
            }
            
            Section {
                Text(viewModel.versionText)
            } footer: {
                Text(viewModel.supportFooterText)
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
