import Foundation
import Combine
import Apollo
import ApolloAPI
import PRCore
import PRModels
import PRNetworking

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

    /// Published reminder lists from the GraphQL cache - source of truth
    @Published public private(set) var reminderLists: [ReminderList] = []

    // Watchers
    private var remindersWatcher: GraphQLWatcher?
    private var userWatcher: GraphQLWatcher?
    private var listsWatcher: GraphQLWatcher?
    private var subscriptionCancellable: Apollo.Cancellable?
    private var listSubscriptionCancellable: Apollo.Cancellable?

    // Refetch listener
    private var refetchCancellable: AnyCancellable?

    /// Callback for when reminders change (for SwiftData integration)
    public var onRemindersChanged: (([Reminder]) -> Void)?
    public var onReminderCreated: ((Reminder) -> Void)?
    public var onReminderUpdated: ((Reminder) -> Void)?
    public var onReminderDeleted: ((UUID) -> Void)?

    /// Callback for when lists change
    public var onListsChanged: (([ReminderList]) -> Void)?

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
            PRLogger.debug("SyncEngine already connected, skipping", category: .sync)
            return
        }

        PRLogger.info("SyncEngine connecting...", category: .sync)

        isConnected = true

        // Connect WebSocket
        GraphQLClient.shared.connect()

        // Start watchers
        setupWatchers()

        // Subscribe to real-time changes
        subscribeToChanges()

        PRLogger.info("SyncEngine connected", category: .sync)
    }

    public func disconnect() {
        PRLogger.info("SyncEngine disconnecting...", category: .sync)

        isConnected = false

        // Cancel watchers
        remindersWatcher?.cancel()
        userWatcher?.cancel()
        listsWatcher?.cancel()
        remindersWatcher = nil
        userWatcher = nil
        listsWatcher = nil

        // Cancel subscriptions
        subscriptionCancellable = nil
        listSubscriptionCancellable = nil

        // Disconnect WebSocket
        GraphQLClient.shared.disconnect()

        PRLogger.info("SyncEngine disconnected", category: .sync)
    }

    // MARK: - Watchers

    private func setupWatchers() {
        setupRemindersWatcher()
        setupUserWatcher()
        setupListsWatcher()
    }

    private func setupRemindersWatcher() {
        PRLogger.debug("Setting up reminders watcher", category: .sync)
        print("👀 Setting up reminders watcher")

        // Cancel existing watcher if any
        remindersWatcher?.cancel()

        let query = PRAPI.RemindersQuery(
            filter: .null,
            pagination: .some(PRAPI.PaginationInput(first: .some(100)))
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
                    self.updateWidgetData()
                }
                PRLogger.info("Reminders watcher received \(reminders.count) reminders", category: .sync)

            case .failure(let error):
                print("👀 Watcher error: \(error)")
                PRLogger.error("Reminders watcher error: \(error)", category: .sync)
                DispatchQueue.main.async {
                    self.syncError = error
                }
            }
        }
    }

    private func setupUserWatcher() {
        PRLogger.debug("Setting up user watcher", category: .sync)

        let query = PRAPI.MeQuery()

        userWatcher = GraphQLClient.shared.watch(query: query) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                let user = self.convertUser(from: data.me)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
                PRLogger.debug("User watcher received user: \(user.email)", category: .sync)

            case .failure(let error):
                PRLogger.error("User watcher error: \(error)", category: .sync)
            }
        }
    }

    private func setupListsWatcher() {
        PRLogger.debug("Setting up lists watcher", category: .sync)
        print("📋 Setting up lists watcher")

        // Cancel existing watcher if any
        listsWatcher?.cancel()

        let query = PRAPI.ReminderListsQuery()

        listsWatcher = GraphQLClient.shared.watch(query: query) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                print("📋 Lists watcher received data, lists: \(data.reminderLists.count)")
                let lists = self.convertReminderLists(from: data)
                DispatchQueue.main.async {
                    print("📋 Updating reminderLists array with \(lists.count) items")
                    self.reminderLists = lists
                    self.onListsChanged?(lists)
                }
                PRLogger.info("Lists watcher received \(lists.count) lists", category: .sync)

            case .failure(let error):
                print("📋 Lists watcher error: \(error)")
                PRLogger.error("Lists watcher error: \(error)", category: .sync)
            }
        }
    }

    // MARK: - Subscription (Real-time Updates from Other Devices)

    private func subscribeToChanges() {
        PRLogger.debug("Subscribing to reminder changes", category: .sync)

        let subscription = PRAPI.ReminderChangedSubscription()
        subscriptionCancellable = GraphQLClient.shared.subscribe(subscription: subscription) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                self.handleReminderChange(data.reminderChanged)
            case .failure(let error):
                PRLogger.error("Subscription error: \(error)", category: .sync)
            }
        }
    }

    private func handleReminderChange(_ event: PRAPI.ReminderChangedSubscription.Data.ReminderChanged) {
        let action = event.action
        let reminderId = event.reminderId

        PRLogger.info("Received reminder change: \(action.rawValue) for \(reminderId)", category: .sync)

        switch action.value {
        case .some(.created):
            guard let reminderData = event.reminder else {
                PRLogger.warning("Received created event without reminder data", category: .sync)
                return
            }
            let reminder = convertSubscriptionReminder(reminderData)
            DispatchQueue.main.async {
                self.onReminderCreated?(reminder)
            }
            // Refetch to update the watcher's cache
            remindersWatcher?.refetch()
            // Also refetch lists to update reminder counts
            listsWatcher?.refetch()

        case .some(.updated):
            guard let reminderData = event.reminder else {
                PRLogger.warning("Received updated event without reminder data", category: .sync)
                return
            }
            let reminder = convertSubscriptionReminder(reminderData)
            DispatchQueue.main.async {
                self.onReminderUpdated?(reminder)
            }
            // Refetch to update the watcher's cache
            remindersWatcher?.refetch()
            // Also refetch lists to update reminder counts (in case list changed)
            listsWatcher?.refetch()

        case .some(.deleted):
            guard let uuid = UUID(uuidString: reminderId) else {
                PRLogger.warning("Invalid UUID in delete event: \(reminderId)", category: .sync)
                return
            }
            DispatchQueue.main.async {
                self.onReminderDeleted?(uuid)
            }
            // Evict from cache and refetch
            GraphQLClient.shared.evictCachedObject(for: reminderId)
            remindersWatcher?.refetch()
            // Also refetch lists to update reminder counts
            listsWatcher?.refetch()

        case .none:
            PRLogger.warning("Unknown change action received", category: .sync)
        }
    }

    // MARK: - Manual Refetch

    /// Manually refetch all data - forces a network request
    public func refetch() {
        PRLogger.debug("Refetching all data", category: .sync)
        print("🔄 SyncEngine.refetch() called")

        // Use fetch with fetchIgnoringCacheData to force network request
        // This ensures we get fresh data and the watcher gets updated
        Task {
            do {
                let query = PRAPI.RemindersQuery(
                    filter: .null,
                    pagination: .some(PRAPI.PaginationInput(first: .some(100)))
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
                    self.updateWidgetData()
                }
                PRLogger.info("Refetch completed with \(reminders.count) reminders", category: .sync)
            } catch {
                print("🔄 Refetch error: \(error)")
                PRLogger.error("Refetch error: \(error)", category: .sync)
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

    private func convertReminderLists(from data: PRAPI.ReminderListsQuery.Data) -> [ReminderList] {
        data.reminderLists.map { listData -> ReminderList in
            ReminderList(
                id: UUID(uuidString: listData.id) ?? UUID(),
                name: listData.name,
                colorHex: listData.colorHex,
                iconName: listData.iconName,
                sortOrder: listData.sortOrder,
                isDefault: listData.isDefault,
                reminderCount: listData.reminderCount,
                createdAt: listData.createdAt.toDate() ?? Date(),
                updatedAt: listData.updatedAt.toDate() ?? Date()
            )
        }
    }

    private func convertReminders(from data: PRAPI.RemindersQuery.Data) -> [Reminder] {
        data.reminders.edges.map { edge -> Reminder in
            convertQueryReminder(edge.node)
        }
    }

    private func convertQueryReminder(_ data: PRAPI.RemindersQuery.Data.Reminders.Edge.Node) -> Reminder {
        let id = UUID(uuidString: data.id) ?? UUID()

        let priority = convertPriority(data.priority)
        let status = convertStatus(data.status)
        let recurrenceRule = data.recurrenceRule.map { convertRecurrenceRule($0) }

        // Parse listId from backend or use default if not set
        let listId: UUID
        if let listIdString = data.listId, let parsedListId = UUID(uuidString: listIdString) {
            listId = parsedListId
        } else {
            // Fallback to default list (first list or hardcoded)
            listId = reminderLists.first(where: { $0.isDefault })?.id ?? Self.defaultListId
        }

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
            updatedAt: data.updatedAt.toDate() ?? Date(),
            listId: listId,
            tags: data.tags
        )
    }

    // Default list ID for reminders (used as fallback)
    private static let defaultListId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func convertSubscriptionReminder(_ data: PRAPI.ReminderChangedSubscription.Data.ReminderChanged.Reminder) -> Reminder {
        let id = UUID(uuidString: data.id) ?? UUID()

        let priority = convertPriority(data.priority)
        let status = convertStatus(data.status)
        let recurrenceRule = data.recurrenceRule.map { convertSubscriptionRecurrenceRule($0) }

        // Parse listId from backend or use default if not set
        let listId: UUID
        if let listIdString = data.listId, let parsedListId = UUID(uuidString: listIdString) {
            listId = parsedListId
        } else {
            listId = reminderLists.first(where: { $0.isDefault })?.id ?? Self.defaultListId
        }

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
            updatedAt: data.updatedAt.toDate() ?? Date(),
            listId: listId,
            tags: data.tags
        )
    }

    private func convertUser(from data: PRAPI.MeQuery.Data.Me) -> User {
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

    private func convertPriority(_ priority: GraphQLEnum<PRAPI.Priority>) -> Priority {
        switch priority.value {
        case .some(.low): return .low
        case .some(.normal): return .normal
        case .some(.high): return .high
        default: return .none
        }
    }

    private func convertStatus(_ status: GraphQLEnum<PRAPI.ReminderStatus>) -> ReminderStatus {
        switch status.value {
        case .some(.active): return .active
        case .some(.completed): return .completed
        case .some(.snoozed): return .snoozed
        case .some(.dismissed): return .dismissed
        case .none: return .active
        }
    }

    private func convertRecurrenceRule(_ rule: PRAPI.RemindersQuery.Data.Reminders.Edge.Node.RecurrenceRule) -> RecurrenceRule {
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

    private func convertSubscriptionRecurrenceRule(_ rule: PRAPI.ReminderChangedSubscription.Data.ReminderChanged.Reminder.RecurrenceRule) -> RecurrenceRule {
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

    private func convertFrequency(_ frequency: GraphQLEnum<PRAPI.Frequency>) -> Frequency {
        switch frequency.value {
        case .some(.hourly): return .hourly
        case .some(.daily): return .daily
        case .some(.weekly): return .weekly
        case .some(.monthly): return .monthly
        case .some(.yearly): return .yearly
        case .none: return .daily
        }
    }

    // MARK: - List Mutations

    /// Creates a new reminder list
    public func createList(name: String, colorHex: String?, iconName: String?) async throws -> ReminderList {
        let input = PRAPI.CreateReminderListInput(
            name: name,
            colorHex: colorHex.map { .some($0) } ?? .null,
            iconName: iconName.map { .some($0) } ?? .null
        )

        let mutation = PRAPI.CreateReminderListMutation(input: input)
        let data = try await GraphQLClient.shared.perform(mutation: mutation)

        let listData = data.createReminderList
        let list = ReminderList(
            id: UUID(uuidString: listData.id) ?? UUID(),
            name: listData.name,
            colorHex: listData.colorHex,
            iconName: listData.iconName,
            sortOrder: listData.sortOrder,
            isDefault: listData.isDefault,
            reminderCount: listData.reminderCount,
            createdAt: listData.createdAt.toDate() ?? Date(),
            updatedAt: listData.updatedAt.toDate() ?? Date()
        )

        // Fetch fresh data and update the published property directly
        let query = PRAPI.ReminderListsQuery()
        let listsData = try await GraphQLClient.shared.fetch(query: query)
        let lists = convertReminderLists(from: listsData)

        await MainActor.run {
            self.reminderLists = lists
            self.onListsChanged?(lists)
        }

        return list
    }

    /// Deletes a reminder list (moves reminders to default list)
    public func deleteList(id: UUID) async throws {
        print("📋 SyncEngine.deleteList: Deleting list with id: \(id.uuidString.lowercased())")
        let mutation = PRAPI.DeleteReminderListMutation(id: id.uuidString.lowercased())
        let result = try await GraphQLClient.shared.perform(mutation: mutation)
        print("📋 SyncEngine.deleteList: Mutation result - deleteReminderList: \(result.deleteReminderList)")

        // Fetch fresh data and update the published property directly
        print("📋 SyncEngine.deleteList: Fetching fresh lists...")
        let query = PRAPI.ReminderListsQuery()
        let data = try await GraphQLClient.shared.fetch(query: query)
        let lists = convertReminderLists(from: data)

        await MainActor.run {
            print("📋 SyncEngine.deleteList: Updating reminderLists with \(lists.count) items")
            self.reminderLists = lists
            self.onListsChanged?(lists)
        }
    }

    /// Updates a reminder list
    public func updateList(id: UUID, name: String?, colorHex: String?, iconName: String?) async throws -> ReminderList {
        let input = PRAPI.UpdateReminderListInput(
            name: name.map { .some($0) } ?? .null,
            colorHex: colorHex.map { .some($0) } ?? .null,
            iconName: iconName.map { .some($0) } ?? .null,
            sortOrder: .null
        )

        let mutation = PRAPI.UpdateReminderListMutation(id: id.uuidString.lowercased(), input: input)
        let data = try await GraphQLClient.shared.perform(mutation: mutation)

        let listData = data.updateReminderList
        let list = ReminderList(
            id: UUID(uuidString: listData.id) ?? UUID(),
            name: listData.name,
            colorHex: listData.colorHex,
            iconName: listData.iconName,
            sortOrder: listData.sortOrder,
            isDefault: listData.isDefault,
            reminderCount: listData.reminderCount,
            createdAt: listData.createdAt.toDate() ?? Date(),
            updatedAt: listData.updatedAt.toDate() ?? Date()
        )

        // Refetch lists to update the watcher
        listsWatcher?.refetch()

        return list
    }

    /// Reorders reminder lists
    public func reorderLists(ids: [UUID]) async throws -> [ReminderList] {
        let mutation = PRAPI.ReorderReminderListsMutation(ids: ids.map { $0.uuidString.lowercased() })
        let data = try await GraphQLClient.shared.perform(mutation: mutation)

        let lists = data.reorderReminderLists.map { listData -> ReminderList in
            ReminderList(
                id: UUID(uuidString: listData.id) ?? UUID(),
                name: listData.name,
                colorHex: listData.colorHex,
                iconName: listData.iconName,
                sortOrder: listData.sortOrder,
                isDefault: listData.isDefault,
                reminderCount: listData.reminderCount,
                createdAt: listData.createdAt.toDate() ?? Date(),
                updatedAt: listData.updatedAt.toDate() ?? Date()
            )
        }

        // Refetch lists to update the watcher
        listsWatcher?.refetch()

        return lists
    }

    // MARK: - Cache Management

    /// Clear the GraphQL cache (useful for logout)
    public func clearCache() {
        GraphQLClient.shared.clearCache()
        DispatchQueue.main.async {
            self.reminders = []
            self.reminderLists = []
            self.currentUser = nil
            WidgetDataService.shared.clearWidgetData()
        }
    }

    // MARK: - Widget Data

    /// Updates widget with current reminders data
    private func updateWidgetData() {
        print("🔄 SyncEngine.updateWidgetData called - reminders count: \(reminders.count)")
        let widgetReminders = reminders.toWidgetReminders(limit: 50)
        print("🔄 SyncEngine.updateWidgetData - widget reminders count: \(widgetReminders.count)")
        WidgetDataService.shared.updateWidget(with: widgetReminders)
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
