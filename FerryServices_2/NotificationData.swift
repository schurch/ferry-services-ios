import Foundation

enum NotificationData: Sendable {
    case service(serviceID: Int)
    case text(message: String)

    init?(_ data: [AnyHashable: Any]) {
        guard let info = data as? [String: AnyObject] else {
            return nil
        }

        if let serviceID = info["service_id"] as? Int {
            self = .service(serviceID: serviceID)
        } else {
            guard
                let aps = info["aps"] as? [String: AnyObject],
                let message = aps["alert"] as? String
            else {
                return nil
            }

            self = .text(message: message)
        }
    }
}
