import SwiftUI
import WebKit

struct WebInformationView: View {
    @State private var viewModel: WebInformationViewModel

    init(html: String) {
        _viewModel = State(initialValue: WebInformationViewModel(html: html))
    }

    var body: some View {
        WebView(viewModel.page)
            .navigationTitle(WebInformationViewModel.Copy.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadHTML() }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIContentSizeCategory.didChangeNotification
                )
            ) { _ in
                Task { await viewModel.loadHTML() }
            }
    }
}

@available(iOS 26.0, *)
#Preview {
    WebInformationView(
        html:
            "<h1>Hello</h1><p>This is a test with a <a href=\"https://www.apple.com\">link</a>.</p>"
    )
}
