import SwiftUI

struct LocationInformation: View {
    let location: Service.Location

    var body: some View {
        let textVerticalSpacing: CGFloat = 4

        VStack(alignment: .leading) {
            Text(location.name)
                .font(.title3)

            if let nextDeparture = location.nextDeparture {
                HStack(alignment: .center) {
                    Image(systemName: "ferry")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.thin)
                        .frame(width: 20)
                        .padding([.leading, .trailing], 12)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Next ferry departure")
                            .font(.subheadline)
                        Text("\(nextDeparture.departure.formatted(Date.timeFormatStyle)) to \(nextDeparture.destination.name)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    .accessibilityElement(children: .combine)
                }

                Divider()
                    .padding(.leading, 55)
            }

            if let railDeparture = location.nextRailDeparture {
                HStack(alignment: .center) {
                    Image(systemName: "lightrail")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.thin)
                        .frame(width: 18)
                        .padding([.leading, .trailing], 14)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Next rail departure")
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(railDeparture.departure.formatted(Date.timeFormatStyle)) to \(railDeparture.to)")
                                .font(.subheadline)
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                            HStack(spacing: 4) {
                                Text(railDeparture.departureInfo)
                                    .foregroundStyle(railDeparture.isCancelled ? Color(UIColor.colorRed) : Color(UIColor.secondaryLabel))
                                if let platform = railDeparture.platform {
                                    Text("•")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .accessibilityHidden(true)
                                    Text("Platform \(platform)")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                Divider()
                    .padding(.leading, 55)
            }

            if let weather = location.weather {
                HStack(alignment: .center) {
                    Image(weather.icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding([.leading, .trailing], 6)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Weather")
                            .font(.subheadline)
                        Text("\(weather.temperatureCelsius)ºC • \(weather.description)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .accessibilityLabel("\(weather.temperatureCelsius)ºC, \(weather.description)")
                    }
                    .accessibilityElement(children: .combine)
                }

                Divider()
                    .padding(.leading, 55)

                HStack(alignment: .center) {
                    Image("Wind")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding([.leading, .trailing], 6)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .rotationEffect(.degrees(Double(weather.windDirection + 180)))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: textVerticalSpacing) {
                        Text("Wind")
                            .font(.subheadline)
                        Text("\(weather.windSpeedMph) MPH • \(weather.windDirectionCardinal)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .accessibilityLabel("\(weather.windSpeedMph) MPH, \(weather.windDirectionCardinal)")
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(UIColor.tertiaryLabel), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ServiceOperator: View {
    let serviceOperator: Service.ServiceOperator
    @Environment(\.openURL) var openURL
    @State private var showingPhoneAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let imageName = serviceOperator.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .accessibilityHidden(true)
                }

                Text(serviceOperator.name)
                    .font(.title2)
            }

            VStack(spacing: 5) {
                HStack {
                    Button("PHONE") {
                        showingPhoneAlert = true
                    }
                    .disabled(serviceOperator.localNumber == nil && serviceOperator.internationalNumber == nil)
                    .confirmationDialog("Phone", isPresented: $showingPhoneAlert) {
                        if let local = serviceOperator.localNumber {
                            let localFormatted = local.replacingOccurrences(of: " ", with: "-")
                            Button(local) {
                                if let url = URL(string: "tel://\(localFormatted)") {
                                    openURL(url)
                                }
                            }
                        }

                        if let international = serviceOperator.internationalNumber {
                            let internationalFormatted = international.replacingOccurrences(of: " ", with: "-")
                            Button(international) {
                                if let url = URL(string: "tel://\(internationalFormatted)") {
                                    openURL(url)
                                }
                            }
                        }
                    }

                    Button("WEBSITE") {
                        if let website = serviceOperator.website, let url = URL(string: website) {
                            openURL(url)
                        }
                    }
                    .disabled(serviceOperator.website == nil)
                }

                HStack {
                    Button("EMAIL") {
                        if let email = serviceOperator.email,
                            let url = URL(string: "mailto:\(email)")
                        {
                            openURL(url)
                        }
                    }
                    .disabled(serviceOperator.email == nil)

                    Button("TWITTER") {
                        if let x = serviceOperator.x, let url = URL(string: x) {
                            openURL(url)
                        }
                    }
                    .disabled(serviceOperator.x == nil)
                }

                HStack {
                    Button("FACEBOOK") {
                        if let facebook = serviceOperator.facebook, let url = URL(string: facebook) {
                            openURL(url)
                        }
                    }
                    .disabled(serviceOperator.facebook == nil)

                    Spacer()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .buttonStyle(.standard)
        }
    }
}

struct DisruptionInfoView: View {
    let service: Service

    var body: some View {
        HStack(spacing: 20) {
            DisruptionIndicator(status: service.status)

            Text(service.disruptionText)

            if !(service.additionalInfo ?? "").isEmpty {
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
            }
        }
        .padding([.top, .bottom], 5)
    }
}

extension Service.Location {
    // Grouped on destination
    var groupedScheduledDepartures: [[Service.Location.ScheduledDeparture]] {
        guard let scheduledDepartures else { return [] }
        let groups = Dictionary(grouping: scheduledDepartures, by: { $0.destination.id })
        return Array(groups.values)
            .sorted(by: { $0.first?.departure ?? Date() < $1.first?.departure ?? Date() })
    }
}

extension ButtonStyle where Self == StandardButtonStyle {
    static var standard: StandardButtonStyle { StandardButtonStyle() }
}

struct StandardButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity, minHeight: 33)
            .foregroundStyle(isEnabled ? Color(UIColor.label) : Color(UIColor.systemGray2))
            .background(Color(UIColor.systemGray5))
            .cornerRadius(6)
    }
}
