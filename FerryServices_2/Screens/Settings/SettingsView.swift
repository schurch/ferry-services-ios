//
//  SettingsView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/06/2024.
//  Copyright © 2024 Stefan Church. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        let version = "Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber)"
        List {
            Section {
                Button("Email") {
                    let url = URL(string: "mailto:stefan.church@gmail.com?subject=Scottish Ferries App (\(version))")!
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                .padding()
                
                Link(
                    "Rate on App Store",
                    destination: URL(string: "https://apps.apple.com/app/id861271891")!
                )
                .padding()
            } header: {
                Text("Hi, I'm Stefan. Thanks for using the Scottish Ferries App. Although I now live overseas, I grew up on the Isle of Arran so can appreciate how vital the ferry services are. If you have any questions or issues please feel free to email me, or if you find the app useful you can also leave a review on the App Store.")
                    .font(.caption)
                    .textCase(nil)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
            } footer: {
                Text(version)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            }
            .listRowInsets(EdgeInsets())
        }
        .background(.colorBackground)
        .scrollContentBackground(.hidden)
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
