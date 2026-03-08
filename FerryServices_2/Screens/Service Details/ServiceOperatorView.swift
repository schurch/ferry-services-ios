import SwiftUI

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
