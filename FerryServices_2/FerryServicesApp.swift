import SwiftUI

@main
struct FerryServicesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var navigationState = AppNavigationState.shared

    var body: some Scene {
        WindowGroup {
            RootView(navigationState: navigationState)
                .tint(.colorTint)
        }
    }
}
