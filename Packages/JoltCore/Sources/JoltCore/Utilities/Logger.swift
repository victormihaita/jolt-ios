import Foundation
import OSLog

/// A simple logging utility for the Jolt app
public enum JoltLogger {
    private static let subsystem = "app.jolt.reminders"

    public enum Category: String {
        case general = "General"
        case network = "Network"
        case sync = "Sync"
        case notifications = "Notifications"
        case auth = "Auth"
        case database = "Database"
        case subscription = "Subscription"
    }

    private static func logger(for category: Category) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    public static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        logger(for: category).debug("\(message, privacy: .public)")
        #endif
    }

    public static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    public static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    public static func error(_ message: String, category: Category = .general) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    public static func error(_ error: Error, category: Category = .general) {
        logger(for: category).error("\(error.localizedDescription, privacy: .public)")
    }
}
