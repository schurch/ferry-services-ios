import SwiftUI
import WebKit

@MainActor
final class WebInformationViewModel: ObservableObject {
    enum Copy {
        static let navigationTitle = "Disruption Information"
    }
    
    let html: String
    let page: WebPage

    init(html: String) {
        self.html = html
        self.page = WebPage(
            configuration: WebPage.Configuration(),
            navigationDecider: NavigationDecider()
        )
    }

    func loadHTML() async {
        let styledHTML = """
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
        _ = page.load(html: styledHTML, baseURL: baseURL)
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
