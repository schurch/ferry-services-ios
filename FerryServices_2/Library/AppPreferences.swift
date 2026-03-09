import Foundation

final class AppPreferences: @unchecked Sendable {
    static let shared = AppPreferences()

    private enum LegacyUserDefaultsKeys {
        static let installationID = "installationID"
    }

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
            if let legacyValue = defaults.string(forKey: LegacyUserDefaultsKeys.installationID),
                let legacyID = UUID(uuidString: legacyValue)
            {
                let currentValue = defaults.string(forKey: UserDefaultsKeys.installationID)
                if currentValue != legacyID.uuidString {
                    defaults.set(legacyID.uuidString, forKey: UserDefaultsKeys.installationID)
                }
                return legacyID
            }

            if let value = defaults.string(forKey: UserDefaultsKeys.installationID),
                let id = UUID(uuidString: value)
            {
                return id
            }

            let id = UUID()
            defaults.set(id.uuidString, forKey: UserDefaultsKeys.installationID)
            defaults.set(id.uuidString, forKey: LegacyUserDefaultsKeys.installationID)
            return id
        }
        set {
            defaults.set(newValue.uuidString, forKey: UserDefaultsKeys.installationID)
            defaults.set(newValue.uuidString, forKey: LegacyUserDefaultsKeys.installationID)
        }
    }

    func registerDefaults() {
        defaults.register(defaults: [UserDefaultsKeys.registeredForNotifications: false])
    }
}
