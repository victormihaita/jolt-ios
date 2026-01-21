import Foundation
import WidgetKit

/// Service for sharing reminder data between the main app and widget extension.
/// Uses App Group UserDefaults for data transfer.
public final class WidgetDataService {
    public static let shared = WidgetDataService()

    private let userDefaults: UserDefaults?
    private let remindersKey = "widget.reminders"
    private let lastUpdatedKey = "widget.lastUpdated"

    private init() {
        userDefaults = UserDefaults(suiteName: PRConstants.AppGroup.identifier)
        print("🔧 WidgetDataService init - App Group: \(PRConstants.AppGroup.identifier)")
        print("🔧 WidgetDataService init - UserDefaults available: \(userDefaults != nil)")
    }

    // MARK: - Data Model

    /// Lightweight reminder struct for widget display.
    /// Codable for JSON serialization to UserDefaults.
    public struct WidgetReminder: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let dueAt: Date
        public let priority: Int
        public let isOverdue: Bool

        public init(id: UUID, title: String, dueAt: Date, priority: Int, isOverdue: Bool) {
            self.id = id
            self.title = title
            self.dueAt = dueAt
            self.priority = priority
            self.isOverdue = isOverdue
        }
    }

    // MARK: - Write (Main App)

    /// Saves reminders to shared storage for widget consumption.
    /// Call this whenever reminders change in the main app.
    public func saveReminders(_ reminders: [WidgetReminder]) {
        print("📦 WidgetDataService.saveReminders called with \(reminders.count) reminders")

        guard let userDefaults = userDefaults else {
            print("❌ WidgetDataService: App Group UserDefaults not available!")
            PRLogger.warning("App Group UserDefaults not available", category: .sync)
            return
        }

        do {
            let data = try JSONEncoder().encode(reminders)
            userDefaults.set(data, forKey: remindersKey)
            userDefaults.set(Date(), forKey: lastUpdatedKey)
            print("✅ WidgetDataService: Saved \(reminders.count) reminders to App Group")
            PRLogger.debug("Saved \(reminders.count) reminders to widget storage", category: .sync)
        } catch {
            print("❌ WidgetDataService: Failed to encode - \(error)")
            PRLogger.error("Failed to encode reminders for widget: \(error)", category: .sync)
        }
    }

    // MARK: - Read (Widget)

    /// Reads reminders from shared storage.
    /// Call this from the widget's TimelineProvider.
    public func loadReminders() -> [WidgetReminder] {
        print("📖 WidgetDataService.loadReminders called")

        guard let userDefaults = userDefaults else {
            print("❌ WidgetDataService: UserDefaults not available for reading")
            return []
        }

        guard let data = userDefaults.data(forKey: remindersKey) else {
            print("⚠️ WidgetDataService: No data found for key '\(remindersKey)'")
            return []
        }

        do {
            let reminders = try JSONDecoder().decode([WidgetReminder].self, from: data)
            print("✅ WidgetDataService: Loaded \(reminders.count) reminders")
            return reminders
        } catch {
            print("❌ WidgetDataService: Failed to decode - \(error)")
            return []
        }
    }

    /// Returns the timestamp when reminders were last updated.
    public func lastUpdated() -> Date? {
        userDefaults?.object(forKey: lastUpdatedKey) as? Date
    }

    // MARK: - Widget Reload

    /// Triggers a widget timeline reload. Call after saving new reminders.
    public func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
        PRLogger.debug("Triggered widget timeline reload", category: .sync)
    }

    /// Convenience method: save reminders AND reload widgets.
    public func updateWidget(with reminders: [WidgetReminder]) {
        saveReminders(reminders)
        reloadWidgetTimelines()
    }

    /// Clears all widget data. Call on logout.
    public func clearWidgetData() {
        userDefaults?.removeObject(forKey: remindersKey)
        userDefaults?.removeObject(forKey: lastUpdatedKey)
        reloadWidgetTimelines()
        PRLogger.debug("Cleared widget data", category: .sync)
    }
}
