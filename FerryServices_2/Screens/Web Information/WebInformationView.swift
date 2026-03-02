import SafariServices
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
        let baseURL = URL(string: "about:blank")!
        _ = page.load(html: styledHtml, baseURL: baseURL)
    }
}

@available(iOS 26.0, *)
private struct NavigationDecider: WebPage.NavigationDeciding {
    @MainActor
    func decidePolicyFor(navigationAction: WebPage.NavigationAction) async
        -> WebPage.NavigationPreferences?
    {
        guard let url = navigationAction.request.url else {
            return WebPage.NavigationPreferences()  // allow by default
        }

        switch url.scheme?.lowercased() {
        case "http", "https":
            await presentSafari(url)
            return nil  // cancel WebView navigation; handled externally
        case "tel", "mailto":
            await UIApplication.shared.open(url)
            return nil  // cancel and open via system
        default:
            return WebPage.NavigationPreferences()  // allow
        }
    }
}

@available(iOS 26.0, *)
@MainActor
private func presentSafari(_ url: URL) async {
    guard
        let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
    else { return }

    let top = topViewController(from: root)
    let safari = SFSafariViewController(url: url)
    top?.present(safari, animated: true)
}

@available(iOS 26.0, *)
@MainActor
private func topViewController(from root: UIViewController?)
    -> UIViewController?
{
    if let nav = root as? UINavigationController {
        return topViewController(from: nav.visibleViewController)
    } else if let tab = root as? UITabBarController {
        return topViewController(from: tab.selectedViewController)
    } else if let presented = root?.presentedViewController {
        return topViewController(from: presented)
    }
    return root
}

@available(iOS 26.0, *)
#Preview {
    WebInformationView(
        html:
            "<h1>Hello</h1><p>This is a test with a <a href=\"https://www.apple.com\">link</a>.</p>"
    )
}
