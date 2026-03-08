import Foundation

enum AppConfig {
    private static let fallbackAPIBaseURL =
        URL(string: "https://scottishferryapp.com") ?? URL(fileURLWithPath: "/")

    static var apiBaseURL: URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            let url = URL(string: value)
        else {
            return fallbackAPIBaseURL
        }
        return url
    }

    static var sentryDSN: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
            !value.isEmpty
        else {
            return nil
        }
        return value
    }
}
