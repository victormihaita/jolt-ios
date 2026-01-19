import Foundation

public struct Reminder: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var priority: Priority
    public var dueAt: Date
    public var allDay: Bool
    public var recurrenceRule: RecurrenceRule?
    public var recurrenceEnd: Date?
    public var status: ReminderStatus
    public var completedAt: Date?
    public var snoozedUntil: Date?
    public var snoozeCount: Int
    public var localId: String?
    public var version: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        priority: Priority = .none,
        dueAt: Date,
        allDay: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        recurrenceEnd: Date? = nil,
        status: ReminderStatus = .active,
        completedAt: Date? = nil,
        snoozedUntil: Date? = nil,
        snoozeCount: Int = 0,
        localId: String? = nil,
        version: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.dueAt = dueAt
        self.allDay = allDay
        self.recurrenceRule = recurrenceRule
        self.recurrenceEnd = recurrenceEnd
        self.status = status
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
        self.snoozeCount = snoozeCount
        self.localId = localId
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isOverdue: Bool {
        status == .active && effectiveDueDate < Date()
    }

    public var isRecurring: Bool {
        recurrenceRule != nil
    }

    public var isSnoozed: Bool {
        if let snoozedUntil = snoozedUntil {
            return status == .snoozed && snoozedUntil > Date()
        }
        return false
    }

    /// The effective due date, accounting for snooze
    public var effectiveDueDate: Date {
        if let snoozedUntil = snoozedUntil, status == .snoozed {
            return snoozedUntil
        }
        return dueAt
    }
}

public enum Priority: Int, Codable, Hashable, Sendable, CaseIterable {
    case none = 0
    case low = 1
    case normal = 2
    case high = 3

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}

public enum ReminderStatus: String, Codable, Hashable, Sendable {
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case snoozed = "SNOOZED"
    case dismissed = "DISMISSED"
}

public struct RecurrenceRule: Codable, Hashable, Sendable {
    public var frequency: Frequency
    public var interval: Int
    public var daysOfWeek: [Int]?
    public var dayOfMonth: Int?
    public var monthOfYear: Int?
    public var endAfterOccurrences: Int?
    public var endDate: Date?

    public init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        monthOfYear: Int? = nil,
        endAfterOccurrences: Int? = nil,
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.monthOfYear = monthOfYear
        self.endAfterOccurrences = endAfterOccurrences
        self.endDate = endDate
    }

    public var displayString: String {
        if interval == 1 {
            return frequency.displayName
        }
        return "Every \(interval) \(frequency.pluralName)"
    }
}

public enum Frequency: String, Codable, Hashable, Sendable, CaseIterable {
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"

    public var displayName: String {
        switch self {
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    public var pluralName: String {
        switch self {
        case .hourly: return "hours"
        case .daily: return "days"
        case .weekly: return "weeks"
        case .monthly: return "months"
        case .yearly: return "years"
        }
    }
}
