import SwiftUI

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
