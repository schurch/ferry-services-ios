import UIKit
import XCTest
@testable import FerryServices_2

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testSupportEmailURLIncludesSubject() {
        let viewModel = SettingsViewModel()

        guard let url = viewModel.supportEmailURL(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return XCTFail("Expected support email URL")
        }

        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, "stefan.church@gmail.com")
        XCTAssertTrue(components.queryItems?.contains(where: { item in
            item.name == "subject" && (item.value?.contains("Scottish Ferries App") ?? false)
        }) == true)
    }

    func testStaticURLsAreConfigured() {
        let viewModel = SettingsViewModel()

        XCTAssertEqual(viewModel.appStoreURL?.absoluteString, "https://apps.apple.com/app/id861271891")
        XCTAssertEqual(
            viewModel.notificationSettingsURL?.absoluteString,
            UIApplication.openNotificationSettingsURLString
        )
    }
}
