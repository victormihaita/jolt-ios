import Foundation
import PRCore

// MARK: - Queued Mutation

/// Represents a mutation queued for offline sync
public struct QueuedMutation: Codable, Identifiable {
    public let id: UUID
    public let operationName: String
    public let operationType: MutationType
    public let entityId: String?
    public let entityType: String
    public let payload: Data
    public let createdAt: Date
    public var retryCount: Int
    public var lastError: String?

    public enum MutationType: String, Codable {
        case create
        case update
        case delete
        case complete
        case snooze
        case dismiss
    }

    public init(
        operationName: String,
        operationType: MutationType,
        entityId: String?,
        entityType: String,
        payload: Data
    ) {
        self.id = UUID()
        self.operationName = operationName
        self.operationType = operationType
        self.entityId = entityId
        self.entityType = entityType
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
        self.lastError = nil
    }
}

// MARK: - Queue Processing Result

/// Result of attempting to process a queued mutation
public enum QueueProcessingResult {
    case success
    case conflict(serverVersion: Int, localVersion: Int)
    case permanentFailure(error: Error)
    case retryableFailure(error: Error)
}

// MARK: - Offline Mutation Queue

/// Manages a queue of mutations to be synced when the device is back online
public final class OfflineMutationQueue: ObservableObject {
    public static let shared = OfflineMutationQueue()

    /// All pending mutations in the queue
    @Published public private(set) var pendingMutations: [QueuedMutation] = []

    /// Whether the queue is currently being processed
    @Published public private(set) var isProcessing = false

    /// The last error that occurred during sync
    @Published public private(set) var lastSyncError: Error?

    private let userDefaults: UserDefaults
    private let queueKey = "com.pr.offlineMutationQueue"
    private let maxRetries = 3

    /// Whether there are pending mutations
    public var hasPendingMutations: Bool {
        !pendingMutations.isEmpty
    }

    /// Number of pending mutations
    public var pendingCount: Int {
        pendingMutations.count
    }

    private init() {
        // Use App Group for sharing with widgets
        self.userDefaults = UserDefaults(suiteName: PRConstants.AppGroup.identifier) ?? .standard
        loadQueue()
    }

    // MARK: - Queue Management

    /// Add a mutation to the queue
    public func enqueue(_ mutation: QueuedMutation) {
        pendingMutations.append(mutation)
        saveQueue()
        PRLogger.info("Queued offline mutation: \(mutation.operationName) for \(mutation.entityType)", category: .sync)
    }

    /// Remove a mutation from the queue by ID
    public func remove(_ mutationId: UUID) {
        pendingMutations.removeAll { $0.id == mutationId }
        saveQueue()
    }

    /// Clear all pending mutations
    public func clearQueue() {
        pendingMutations.removeAll()
        lastSyncError = nil
        saveQueue()
        PRLogger.info("Cleared offline mutation queue", category: .sync)
    }

    /// Clear the last sync error
    public func clearError() {
        lastSyncError = nil
    }

    // MARK: - Persistence

    private func loadQueue() {
        guard let data = userDefaults.data(forKey: queueKey),
              let mutations = try? JSONDecoder().decode([QueuedMutation].self, from: data) else {
            return
        }
        pendingMutations = mutations
        if !mutations.isEmpty {
            PRLogger.info("Loaded \(mutations.count) queued mutations from disk", category: .sync)
        }
    }

    private func saveQueue() {
        guard let data = try? JSONEncoder().encode(pendingMutations) else {
            PRLogger.error("Failed to encode mutation queue", category: .sync)
            return
        }
        userDefaults.set(data, forKey: queueKey)
    }

    // MARK: - Queue Processing

    /// Process all queued mutations in order (FIFO).
    /// Called by SyncEngine when network becomes available.
    /// - Parameter processor: Closure that processes a single mutation and returns the result
    /// - Returns: Number of successfully processed mutations
    @MainActor
    public func processQueue(
        using processor: @escaping (QueuedMutation) async -> QueueProcessingResult
    ) async -> Int {
        guard !isProcessing else {
            PRLogger.debug("Queue already processing, skipping", category: .sync)
            return 0
        }

        guard !pendingMutations.isEmpty else {
            return 0
        }

        isProcessing = true
        lastSyncError = nil
        var successCount = 0

        PRLogger.info("Processing \(pendingMutations.count) queued mutations", category: .sync)

        // Process in FIFO order
        let mutationsToProcess = pendingMutations
        for mutation in mutationsToProcess {
            let result = await processor(mutation)

            switch result {
            case .success:
                remove(mutation.id)
                successCount += 1
                PRLogger.debug("Successfully synced: \(mutation.operationName)", category: .sync)

            case .conflict(let serverVersion, let localVersion):
                // Server wins - remove from queue
                PRLogger.warning(
                    "Conflict for \(mutation.operationName): server v\(serverVersion) vs local v\(localVersion)",
                    category: .sync
                )
                remove(mutation.id)

            case .permanentFailure(let error):
                // Remove failed mutation
                PRLogger.error("Permanent failure for \(mutation.operationName): \(error)", category: .sync)
                lastSyncError = error
                remove(mutation.id)

            case .retryableFailure(let error):
                // Update retry count
                if let index = pendingMutations.firstIndex(where: { $0.id == mutation.id }) {
                    var updated = pendingMutations[index]
                    updated.retryCount += 1
                    updated.lastError = error.localizedDescription

                    if updated.retryCount >= maxRetries {
                        PRLogger.error("Max retries reached for \(mutation.operationName)", category: .sync)
                        lastSyncError = error
                        remove(mutation.id)
                    } else {
                        pendingMutations[index] = updated
                        saveQueue()
                        PRLogger.warning(
                            "Retry \(updated.retryCount)/\(maxRetries) for \(mutation.operationName)",
                            category: .sync
                        )
                    }
                }
            }
        }

        isProcessing = false

        let remaining = pendingMutations.count
        PRLogger.info(
            "Queue processing complete: \(successCount) succeeded, \(remaining) remaining",
            category: .sync
        )

        return successCount
    }
}

// MARK: - Mutation Payload Types

/// Serializable payload for CreateReminder mutation
public struct CreateReminderPayload: Codable {
    public let title: String
    public let notes: String?
    public let listId: String?
    public let dueAt: String?
    public let allDay: Bool?
    public let priority: String
    public let localId: String
    public let recurrenceRule: RecurrenceRulePayload?
    public let recurrenceEnd: String?
    public let tags: [String]?

    public init(
        title: String,
        notes: String?,
        listId: String?,
        dueAt: String?,
        allDay: Bool?,
        priority: String,
        localId: String,
        recurrenceRule: RecurrenceRulePayload?,
        recurrenceEnd: String?,
        tags: [String]?
    ) {
        self.title = title
        self.notes = notes
        self.listId = listId
        self.dueAt = dueAt
        self.allDay = allDay
        self.priority = priority
        self.localId = localId
        self.recurrenceRule = recurrenceRule
        self.recurrenceEnd = recurrenceEnd
        self.tags = tags
    }
}

/// Serializable payload for recurrence rules
public struct RecurrenceRulePayload: Codable {
    public let frequency: String
    public let interval: Int
    public let daysOfWeek: [Int]?
    public let dayOfMonth: Int?
    public let monthOfYear: Int?
    public let endAfterOccurrences: Int?
    public let endDate: String?

    public init(
        frequency: String,
        interval: Int,
        daysOfWeek: [Int]?,
        dayOfMonth: Int?,
        monthOfYear: Int?,
        endAfterOccurrences: Int?,
        endDate: String?
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.monthOfYear = monthOfYear
        self.endAfterOccurrences = endAfterOccurrences
        self.endDate = endDate
    }
}

/// Serializable payload for UpdateReminder mutation
public struct UpdateReminderPayload: Codable {
    public let id: String
    public let title: String?
    public let notes: String?
    public let listId: String?
    public let dueAt: String?
    public let allDay: Bool?
    public let priority: String?
    public let status: String?
    public let recurrenceRule: RecurrenceRulePayload?
    public let recurrenceEnd: String?
    public let tags: [String]?
    public let version: Int

    public init(
        id: String,
        title: String?,
        notes: String?,
        listId: String?,
        dueAt: String?,
        allDay: Bool?,
        priority: String?,
        status: String?,
        recurrenceRule: RecurrenceRulePayload?,
        recurrenceEnd: String?,
        tags: [String]?,
        version: Int
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.listId = listId
        self.dueAt = dueAt
        self.allDay = allDay
        self.priority = priority
        self.status = status
        self.recurrenceRule = recurrenceRule
        self.recurrenceEnd = recurrenceEnd
        self.tags = tags
        self.version = version
    }
}

/// Serializable payload for DeleteReminder mutation
public struct DeleteReminderPayload: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

/// Serializable payload for CompleteReminder mutation
public struct CompleteReminderPayload: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

/// Serializable payload for SnoozeReminder mutation
public struct SnoozeReminderPayload: Codable {
    public let id: String
    public let minutes: Int

    public init(id: String, minutes: Int) {
        self.id = id
        self.minutes = minutes
    }
}

/// Serializable payload for DismissReminder mutation
public struct DismissReminderPayload: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

// MARK: - QueuedMutation Factory Methods

public extension QueuedMutation {
    /// Create a queued mutation for CreateReminder
    static func createReminder(_ payload: CreateReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "CreateReminder",
            operationType: .create,
            entityId: payload.localId,
            entityType: "Reminder",
            payload: data
        )
    }

    /// Create a queued mutation for UpdateReminder
    static func updateReminder(_ payload: UpdateReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "UpdateReminder",
            operationType: .update,
            entityId: payload.id,
            entityType: "Reminder",
            payload: data
        )
    }

    /// Create a queued mutation for DeleteReminder
    static func deleteReminder(_ payload: DeleteReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "DeleteReminder",
            operationType: .delete,
            entityId: payload.id,
            entityType: "Reminder",
            payload: data
        )
    }

    /// Create a queued mutation for CompleteReminder
    static func completeReminder(_ payload: CompleteReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "CompleteReminder",
            operationType: .complete,
            entityId: payload.id,
            entityType: "Reminder",
            payload: data
        )
    }

    /// Create a queued mutation for SnoozeReminder
    static func snoozeReminder(_ payload: SnoozeReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "SnoozeReminder",
            operationType: .snooze,
            entityId: payload.id,
            entityType: "Reminder",
            payload: data
        )
    }

    /// Create a queued mutation for DismissReminder
    static func dismissReminder(_ payload: DismissReminderPayload) -> QueuedMutation? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return QueuedMutation(
            operationName: "DismissReminder",
            operationType: .dismiss,
            entityId: payload.id,
            entityType: "Reminder",
            payload: data
        )
    }
}
