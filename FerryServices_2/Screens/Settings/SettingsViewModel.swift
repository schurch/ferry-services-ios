import Foundation
import UIKit
import UserNotifications

enum SettingsNotificationsState {
    case loading
    case authorized(isOn: Bool)
    case notAuthorized
    case error
}

@MainActor
final class SettingsViewModel: ObservableObject {
    enum Copy {
        static let pushNotificationsTitle = "Push Notifications"
        static let enableNotificationsInSettings = "Enable notifications in Settings"
        static let notificationsStatusError = "An error occured fetching the notification status"
        static let contactSectionTitle = "Contact"
        static let emailButtonTitle = "Email"
        static let rateButtonTitle = "Rate on App Store"
        static let supportFooter = "Hi, I'm Stefan. Thanks for using the Scottish Ferries App. Although I now live overseas, I grew up on the Isle of Arran so can appreciate how vital the ferry services are. If you have any questions or issues please feel free to email me, or if you find the app useful you can also leave a review on the App Store."
    }
    
    @Published var notificationsState: SettingsNotificationsState = .loading

    var versionText: String {
        "Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber)"
    }
    
    var supportFooterText: String { Copy.supportFooter }

    func toggleNotifications(isEnabled: Bool) {
        Task {
            notificationsState = .loading

            do {
                try await APIClient.updatePushEnabledStatus(
                    installationID: Installation.id,
                    isEnabled: isEnabled
                )
                notificationsState = .authorized(isOn: isEnabled)
            } catch {
                notificationsState = .authorized(isOn: !isEnabled)
            }
        }
    }

    func refreshNotificationState() async {
        guard await areNotificationsAuthorized() else {
            notificationsState = .notAuthorized
            return
        }

        do {
            let enabled = try await APIClient.getPushEnabledStatus(
                installationID: Installation.id
            )
            notificationsState = .authorized(isOn: enabled)
        } catch {
            notificationsState = .error
        }
    }

    func supportEmailURL() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "stefan.church@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Scottish Ferries App (\(versionText))")
        ]
        return components.url
    }

    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id861271891")
    }

    var notificationSettingsURL: URL? {
        URL(string: UIApplication.openNotificationSettingsURLString)
    }

    private func areNotificationsAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

private extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    var buildVersionNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}
