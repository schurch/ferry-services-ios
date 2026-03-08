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
