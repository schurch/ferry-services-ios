import SwiftUI
import WebKit

struct WebInformationView: View {
    let html: String
    @State private var page: WebPage

    init(html: String) {
        self.html = html
        self._page = State(
            initialValue: WebPage(
                configuration: WebPage.Configuration(),
                navigationDecider: NavigationDecider()
            )
        )
    }

    var body: some View {
        WebView(page)
            .navigationTitle("Disruption Information")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadHtml() }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIContentSizeCategory.didChangeNotification
                )
            ) { _ in
                Task { await loadHtml() }
            }
    }

    private func loadHtml() async {
        let styledHtml = """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta name='viewport' content='width=device-width, initial-scale=1'>
                    <style type='text/css'>
                        :root {
                            color-scheme: light dark;
                        }
                        body { font: -apple-system-body; }
                        a { color: #21BFAA; }
                    </style>
                </head>
                <body>
                    \(html)
                </body>
            </html>
            """
        guard let baseURL = URL(string: "about:blank") else { return }
        _ = page.load(html: styledHtml, baseURL: baseURL)
    }
}

@available(iOS 26.0, *)
private struct NavigationDecider: WebPage.NavigationDeciding {
    @MainActor
    mutating func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        guard let url = action.request.url else {
            return .allow
        }

        switch url.scheme?.lowercased() {
        case "http", "https":
            await UIApplication.shared.open(url)
            return .cancel
        case "tel", "mailto":
            await UIApplication.shared.open(url)
            return .cancel
        default:
            return .allow
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
