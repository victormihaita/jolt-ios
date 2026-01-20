import Foundation
import Combine
import Apollo
import ApolloAPI
import JoltCore
import JoltModels
import JoltNetworking

/// Engine responsible for synchronizing reminders between local storage and the server.
/// Uses Apollo GraphQL watchers to keep data in sync across all devices.
public final class SyncEngine: ObservableObject {
    public static let shared = SyncEngine()

    @Published public private(set) var isSyncing = false
    @Published public private(set) var lastSyncAt: Date?
    @Published public private(set) var syncError: Error?

    /// Published reminders from the GraphQL cache - source of truth
    @Published public private(set) var reminders: [Reminder] = []
    @Published public private(set) var currentUser: User?

    // Watchers
    private var remindersWatcher: GraphQLWatcher?
    private var userWatcher: GraphQLWatcher?
    private var subscriptionCancellable: Apollo.Cancellable?

    // Refetch listener
    private var refetchCancellable: AnyCancellable?

    /// Callback for when reminders change (for SwiftData integration)
    public var onRemindersChanged: (([Reminder]) -> Void)?
    public var onReminderCreated: ((Reminder) -> Void)?
    public var onReminderUpdated: ((Reminder) -> Void)?
    public var onReminderDeleted: ((UUID) -> Void)?

    private init() {
        setupRefetchListener()
    }

    // MARK: - Setup

    private func setupRefetchListener() {
        print("🔔 SyncEngine: Setting up refetch listener")
        refetchCancellable = NotificationCenter.default
            .publisher(for: GraphQLClient.refetchNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🔔 SyncEngine: Received refetch notification")
                self?.refetch()
            }
    }

    // MARK: - Connection Management

    private var isConnected = false

    public func connect() {
        // Guard against duplicate connections
        guard !isConnected else {
            JoltLogger.debug("SyncEngine already connected, skipping", category: .sync)
            return
        }

        JoltLogger.info("SyncEngine connecting...", category: .sync)

        isConnected = true

        // Connect WebSocket
        GraphQLClient.shared.connect()

        // Start watchers
        setupWatchers()

        // Subscribe to real-time changes
        subscribeToChanges()

        JoltLogger.info("SyncEngine connected", category: .sync)
    }

    public func disconnect() {
        JoltLogger.info("SyncEngine disconnecting...", category: .sync)

        isConnected = false

        // Cancel watchers
        remindersWatcher?.cancel()
        userWatcher?.cancel()
        remindersWatcher = nil
        userWatcher = nil

        // Cancel subscription
        subscriptionCancellable = nil

        // Disconnect WebSocket
        GraphQLClient.shared.disconnect()

        JoltLogger.info("SyncEngine disconnected", category: .sync)
    }

    // MARK: - Watchers

    private func setupWatchers() {
        setupRemindersWatcher()
        setupUserWatcher()
    }

    private func setupRemindersWatcher() {
        JoltLogger.debug("Setting up reminders watcher", category: .sync)
        print("👀 Setting up reminders watcher")

        // Cancel existing watcher if any
        remindersWatcher?.cancel()

        let query = JoltAPI.RemindersQuery(
            filter: .null,
            pagination: .some(JoltAPI.PaginationInput(first: .some(100)))
        )

        remindersWatcher = GraphQLClient.shared.watch(query: query) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                print("👀 Watcher received data, edges: \(data.reminders.edges.count)")
                let reminders = self.convertReminders(from: data)
                DispatchQueue.main.async {
                    print("👀 Updating reminders array with \(reminders.count) items")
                    self.reminders = reminders
                    self.onRemindersChanged?(reminders)
                    self.lastSyncAt = Date()
                }
                JoltLogger.info("Reminders watcher received \(reminders.count) reminders", category: .sync)

            case .failure(let error):
                print("👀 Watcher error: \(error)")
                JoltLogger.error("Reminders watcher error: \(error)", category: .sync)
                DispatchQueue.main.async {
                    self.syncError = error
                }
            }
        }
    }

    private func setupUserWatcher() {
        JoltLogger.debug("Setting up user watcher", category: .sync)

        let query = JoltAPI.MeQuery()

        userWatcher = GraphQLClient.shared.watch(query: query) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                let user = self.convertUser(from: data.me)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
                JoltLogger.debug("User watcher received user: \(user.email)", category: .sync)

            case .failure(let error):
                JoltLogger.error("User watcher error: \(error)", category: .sync)
            }
        }
    }

    // MARK: - Subscription (Real-time Updates from Other Devices)

    private func subscribeToChanges() {
        JoltLogger.debug("Subscribing to reminder changes", category: .sync)

        let subscription = JoltAPI.ReminderChangedSubscription()
        subscriptionCancellable = GraphQLClient.shared.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                self.handleReminderChange(data.reminderChanged)
            case .failure(let error):
                JoltLogger.error("Subscription error: \(error)", category: .sync)
            }
        }
    }

    private func handleReminderChange(_ event: JoltAPI.ReminderChangedSubscription.Data.ReminderChanged) {
        let action = event.action
        let reminderId = event.reminderId

        JoltLogger.info("Received reminder change: \(action.rawValue) for \(reminderId)", category: .sync)

        switch action.value {
        case .some(.created):
            guard let reminderData = event.reminder else {
                JoltLogger.warning("Received created event without reminder data", category: .sync)
                return
            }
            let reminder = convertSubscriptionReminder(reminderData)
            DispatchQueue.main.async {
                self.onReminderCreated?(reminder)
            }
            // Refetch to update the watcher's cache
            remindersWatcher?.refetch()

        case .some(.updated):
            guard let reminderData = event.reminder else {
                JoltLogger.warning("Received updated event without reminder data", category: .sync)
                return
            }
            let reminder = convertSubscriptionReminder(reminderData)
            DispatchQueue.main.async {
                self.onReminderUpdated?(reminder)
            }
            // Refetch to update the watcher's cache
            remindersWatcher?.refetch()

        case .some(.deleted):
            guard let uuid = UUID(uuidString: reminderId) else {
                JoltLogger.warning("Invalid UUID in delete event: \(reminderId)", category: .sync)
                return
            }
            DispatchQueue.main.async {
                self.onReminderDeleted?(uuid)
            }
            // Evict from cache and refetch
            GraphQLClient.shared.evictCachedObject(for: reminderId)
            remindersWatcher?.refetch()

        case .none:
            JoltLogger.warning("Unknown change action received", category: .sync)
        }
    }

    // MARK: - Manual Refetch

    /// Manually refetch all data - forces a network request
    public func refetch() {
        JoltLogger.debug("Refetching all data", category: .sync)
        print("🔄 SyncEngine.refetch() called")

        // Use fetch with fetchIgnoringCacheData to force network request
        // This ensures we get fresh data and the watcher gets updated
        Task {
            do {
                let query = JoltAPI.RemindersQuery(
                    filter: .null,
                    pagination: .some(JoltAPI.PaginationInput(first: .some(100)))
                )
                print("🔄 Fetching reminders from server...")
                let data = try await GraphQLClient.shared.fetch(query: query, storeInCache: true)
                print("🔄 Got response, edges count: \(data.reminders.edges.count)")
                let reminders = self.convertReminders(from: data)
                print("🔄 Converted \(reminders.count) reminders")

                await MainActor.run {
                    print("🔄 Updating published reminders array")
                    self.reminders = reminders
                    self.onRemindersChanged?(reminders)
                    self.lastSyncAt = Date()
                }
                JoltLogger.info("Refetch completed with \(reminders.count) reminders", category: .sync)
            } catch {
                print("🔄 Refetch error: \(error)")
                JoltLogger.error("Refetch error: \(error)", category: .sync)
            }
        }
    }

    /// Perform a full sync (alias for refetch for API compatibility)
    public func performSync() async {
        refetch()
    }

    /// Legacy sync method for compatibility
    public func sync() async {
        refetch()
    }

    // MARK: - Data Conversion

    private func convertReminders(from data: JoltAPI.RemindersQuery.Data) -> [Reminder] {
        data.reminders.edges.map { edge -> Reminder in
            convertQueryReminder(edge.node)
        }
    }

    private func convertQueryReminder(_ data: JoltAPI.RemindersQuery.Data.Reminders.Edge.Node) -> Reminder {
        let id = UUID(uuidString: data.id) ?? UUID()

        let priority = convertPriority(data.priority)
        let status = convertStatus(data.status)
        let recurrenceRule = data.recurrenceRule.map { convertRecurrenceRule($0) }

        return Reminder(
            id: id,
            title: data.title,
            notes: data.notes,
            priority: priority,
            dueAt: data.dueAt.toDate() ?? Date(),
            allDay: data.allDay,
            recurrenceRule: recurrenceRule,
            recurrenceEnd: data.recurrenceEnd?.toDate(),
            status: status,
            completedAt: data.completedAt?.toDate(),
            snoozedUntil: data.snoozedUntil?.toDate(),
            snoozeCount: data.snoozeCount,
            localId: data.localId,
            version: data.version,
            createdAt: data.createdAt.toDate() ?? Date(),
            updatedAt: data.updatedAt.toDate() ?? Date()
        )
    }

    private func convertSubscriptionReminder(_ data: JoltAPI.ReminderChangedSubscription.Data.ReminderChanged.Reminder) -> Reminder {
        let id = UUID(uuidString: data.id) ?? UUID()

        let priority = convertPriority(data.priority)
        let status = convertStatus(data.status)
        let recurrenceRule = data.recurrenceRule.map { convertSubscriptionRecurrenceRule($0) }

        return Reminder(
            id: id,
            title: data.title,
            notes: data.notes,
            priority: priority,
            dueAt: data.dueAt.toDate() ?? Date(),
            allDay: data.allDay,
            recurrenceRule: recurrenceRule,
            recurrenceEnd: data.recurrenceEnd?.toDate(),
            status: status,
            completedAt: data.completedAt?.toDate(),
            snoozedUntil: data.snoozedUntil?.toDate(),
            snoozeCount: data.snoozeCount,
            localId: data.localId,
            version: data.version,
            createdAt: data.createdAt.toDate() ?? Date(),
            updatedAt: data.updatedAt.toDate() ?? Date()
        )
    }

    private func convertUser(from data: JoltAPI.MeQuery.Data.Me) -> User {
        User(
            id: UUID(uuidString: data.id) ?? UUID(),
            email: data.email,
            displayName: data.displayName,
            avatarUrl: data.avatarUrl,
            timezone: data.timezone,
            isPremium: data.isPremium,
            premiumUntil: data.premiumUntil?.toDate()
        )
    }

    private func convertPriority(_ priority: GraphQLEnum<JoltAPI.Priority>) -> Priority {
        switch priority.value {
        case .some(.low): return .low
        case .some(.normal): return .normal
        case .some(.high): return .high
        default: return .none
        }
    }

    private func convertStatus(_ status: GraphQLEnum<JoltAPI.ReminderStatus>) -> ReminderStatus {
        switch status.value {
        case .some(.active): return .active
        case .some(.completed): return .completed
        case .some(.snoozed): return .snoozed
        case .some(.dismissed): return .dismissed
        case .none: return .active
        }
    }

    private func convertRecurrenceRule(_ rule: JoltAPI.RemindersQuery.Data.Reminders.Edge.Node.RecurrenceRule) -> RecurrenceRule {
        let frequency = convertFrequency(rule.frequency)

        return RecurrenceRule(
            frequency: frequency,
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek,
            dayOfMonth: rule.dayOfMonth,
            monthOfYear: rule.monthOfYear,
            endAfterOccurrences: rule.endAfterOccurrences,
            endDate: rule.endDate?.toDate()
        )
    }

    private func convertSubscriptionRecurrenceRule(_ rule: JoltAPI.ReminderChangedSubscription.Data.ReminderChanged.Reminder.RecurrenceRule) -> RecurrenceRule {
        let frequency = convertFrequency(rule.frequency)

        return RecurrenceRule(
            frequency: frequency,
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek,
            dayOfMonth: rule.dayOfMonth,
            monthOfYear: rule.monthOfYear,
            endAfterOccurrences: rule.endAfterOccurrences,
            endDate: rule.endDate?.toDate()
        )
    }

    private func convertFrequency(_ frequency: GraphQLEnum<JoltAPI.Frequency>) -> Frequency {
        switch frequency.value {
        case .some(.hourly): return .hourly
        case .some(.daily): return .daily
        case .some(.weekly): return .weekly
        case .some(.monthly): return .monthly
        case .some(.yearly): return .yearly
        case .none: return .daily
        }
    }

    // MARK: - Cache Management

    /// Clear the GraphQL cache (useful for logout)
    public func clearCache() {
        GraphQLClient.shared.clearCache()
        DispatchQueue.main.async {
            self.reminders = []
            self.currentUser = nil
        }
    }
}

// MARK: - Date Conversion

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: self) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}

// MARK: - Refetchable Protocol

/// Protocol for views/view models that can refetch their data
public protocol Refetchable {
    func refetch()
}
