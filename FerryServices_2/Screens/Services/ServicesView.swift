//
//  ServicesView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 13/08/23.
//  Copyright © 2023 Stefan Church. All rights reserved.
//

import SwiftUI

struct ServicesView: View {
    
    var showService: (Service) -> Void
    
    @StateObject private var viewModel = ServicesViewModel()
    
    var body: some View {
        List {
            switch viewModel.sections {
            case .single(let rows):
                ForEach(rows) { row in
                    ServiceRow(row: row, showService: showService)
                }
                
            case .multiple(let sections):
                ForEach(sections) { section in
                    ServicesSection(section: section, showService: showService)
                }
            }
        }
        .background(.colorBackground)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $viewModel.searchText)
        .autocorrectionDisabled()
        .task {
            await viewModel.fetchServices()
        }
        .refreshable {
            await viewModel.fetchServices()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await viewModel.fetchServices()
            }
        }
    }
}

private struct ServicesSection: View {
    var section: ServicesViewModel.Sections.Section
    var showService: (Service) -> Void
    
    var body: some View {
        Section {
            ForEach(section.rows) { row in
                ServiceRow(row: row, showService: showService)
            }
        } header: {
            if let systemImageName = section.systemImageName {
                HStack {
                    Image(systemName: systemImageName)
                        .accessibilityHidden(true)
                    Text(section.title)
                }
            } else if section.usesAssetImage, let imageName = section.imageName {
                HStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .accessibilityHidden(true)
                    Text(section.title)
                }
            } else {
                Text(section.title)
            }
        }
    }
}

private struct ServiceRow: View {
    var row: ServicesViewModel.Sections.Row
    var showService: (Service) -> Void
    
    var body: some View {
        Button {
            showService(row.service)
        } label: {
            HStack {
                DisruptionIndicator(status: row.status)
                    .padding(.trailing, 4)
                VStack(alignment: .leading, spacing: 0) {
                    Text(row.area)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(row.route)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(row.disruptionText)
                        .font(.subheadline.bold())
                        .foregroundStyle(row.status.statusColor)
                        .padding(.top, 5)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(Font.system(.caption).weight(.bold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.top, 2)
            .padding(.bottom, 2)
        }
        .accessibilityElement(children: .combine)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}
