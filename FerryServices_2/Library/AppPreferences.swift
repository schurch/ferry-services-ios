import Foundation

final class AppPreferences: @unchecked Sendable {
    static let shared = AppPreferences()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var subscribedServiceIDs: [Int] {
        get {
            defaults.array(forKey: UserDefaultsKeys.subscribedService) as? [Int] ?? []
        }
        set {
            defaults.set(newValue, forKey: UserDefaultsKeys.subscribedService)
        }
    }

    var isRegisteredForNotifications: Bool {
        get {
            defaults.bool(forKey: UserDefaultsKeys.registeredForNotifications)
        }
        set {
            defaults.set(newValue, forKey: UserDefaultsKeys.registeredForNotifications)
        }
    }

    var installationID: UUID {
        get {
            if let value = defaults.string(forKey: UserDefaultsKeys.installationID),
                let id = UUID(uuidString: value)
            {
                return id
            }

            let id = UUID()
            defaults.set(id.uuidString, forKey: UserDefaultsKeys.installationID)
            return id
        }
        set {
            defaults.set(newValue.uuidString, forKey: UserDefaultsKeys.installationID)
        }
    }

    func registerDefaults() {
        defaults.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])
    }
}
