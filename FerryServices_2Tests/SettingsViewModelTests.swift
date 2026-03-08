import Testing
import UIKit
@testable import FerryServices_2

@Suite
struct SettingsViewModelTests {
    @Test @MainActor
    func supportEmailURLIncludesSubject() {
        let viewModel = SettingsViewModel()

        guard let url = viewModel.supportEmailURL(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Expected support email URL")
            return
        }

        #expect(components.scheme == "mailto")
        #expect(components.path == "stefan.church@gmail.com")
        #expect(
            components.queryItems?.contains(where: { item in
                item.name == "subject" && (item.value?.contains("Scottish Ferries App") ?? false)
            }) == true
        )
    }

    @Test @MainActor
    func staticURLsAreConfigured() {
        let viewModel = SettingsViewModel()

        #expect(viewModel.appStoreURL?.absoluteString == "https://apps.apple.com/app/id861271891")
        #expect(
            viewModel.notificationSettingsURL?.absoluteString == UIApplication.openNotificationSettingsURLString
        )
    }
}
