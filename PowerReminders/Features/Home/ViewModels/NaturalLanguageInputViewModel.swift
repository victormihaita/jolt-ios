import SwiftUI
import Combine
import PRModels
import PRNetworking
import PRSync

@MainActor
class NaturalLanguageInputViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var inputText = ""
    @Published var parsedReminder: ParsedReminder?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let syncEngine = SyncEngine.shared
    private let graphQL = GraphQLClient.shared
    private var cancellables = Set<AnyCancellable>()

    /// The list ID to use for creating reminders
    let listId: UUID

    // MARK: - Computed Properties

    var canSubmit: Bool {
        guard let parsed = parsedReminder else { return false }
        return !parsed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(listId: UUID) {
        self.listId = listId
        setupTextObserver()
    }

    private func setupTextObserver() {
        $inputText
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.parseInput(text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Parsing

    private func parseInput(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parsedReminder = nil
        } else {
            parsedReminder = NaturalLanguageParser.parse(text)
        }
    }

    // MARK: - Reminder Creation

    /// Creates a reminder from the current parsed input
    /// - Returns: The created Reminder if successful, nil otherwise
    func createReminder() async -> PRModels.Reminder? {
        guard let parsed = parsedReminder,
              !parsed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            // Determine due date - if no date parsed, use end of today with allDay = true
            let (dueAt, allDay) = determineDueDate(from: parsed)

            let input = PRAPI.CreateReminderInput(
                listId: .some(listId.uuidString.lowercased()),
                title: parsed.title,
                notes: .null,
                priority: .some(.init(graphQLPriority(from: parsed.priority))),
                dueAt: iso8601String(from: dueAt),
                allDay: allDay,
                recurrenceRule: parsed.recurrence != nil
                    ? .some(graphQLRecurrenceRuleInput(from: parsed.recurrence!))
                    : .null
            )

            let mutation = PRAPI.CreateReminderMutation(input: input)
            print("✨ NaturalLanguageInput: Creating reminder '\(parsed.title)' in list \(listId)...")
            let result = try await graphQL.perform(mutation: mutation)
            print("✨ NaturalLanguageInput: Reminder created with id: \(result.createReminder.id)")

            // Create a local Reminder object to return
            let reminder = PRModels.Reminder(
                id: UUID(uuidString: result.createReminder.id) ?? UUID(),
                title: parsed.title,
                notes: nil,
                priority: parsed.priority,
                dueAt: dueAt,
                allDay: allDay,
                recurrenceRule: parsed.recurrence,
                recurrenceEnd: nil,
                status: .active,
                completedAt: nil,
                snoozedUntil: nil,
                snoozeCount: 0,
                localId: nil,
                version: 1,
                createdAt: Date(),
                updatedAt: Date(),
                listId: listId,
                tags: parsed.tags
            )

            isLoading = false
            return reminder

        } catch {
            print("❌ NaturalLanguageInput: Failed to create reminder: \(error)")
            isLoading = false
            errorMessage = "Failed to create reminder: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Helper Methods

    private func determineDueDate(from parsed: ParsedReminder) -> (Date, Bool) {
        if let dueDate = parsed.dueDate {
            // User specified a date/time
            // Check if the time component is midnight (likely just a date, no time specified)
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: dueDate)
            let isMidnight = components.hour == 0 && components.minute == 0

            // If it's exactly midnight, treat as all-day (unless it was explicitly "at 12am")
            // For simplicity, assume no time = all day
            return (dueDate, isMidnight)
        } else {
            // No date specified - use end of today with allDay = true
            let calendar = Calendar.current
            let endOfDay = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60 - 1)
            return (endOfDay, true)
        }
    }

    private func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func graphQLPriority(from priority: PRModels.Priority) -> PRAPI.Priority {
        switch priority {
        case .none: return .none
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        }
    }

    private func graphQLFrequency(from frequency: PRModels.Frequency) -> PRAPI.Frequency {
        switch frequency {
        case .hourly: return .hourly
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }

    private func graphQLRecurrenceRuleInput(from rule: PRModels.RecurrenceRule) -> PRAPI.RecurrenceRuleInput {
        PRAPI.RecurrenceRuleInput(
            frequency: .init(graphQLFrequency(from: rule.frequency)),
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek != nil ? .some(rule.daysOfWeek!) : .null,
            dayOfMonth: rule.dayOfMonth != nil ? .some(rule.dayOfMonth!) : .null,
            monthOfYear: rule.monthOfYear != nil ? .some(rule.monthOfYear!) : .null,
            endAfterOccurrences: rule.endAfterOccurrences != nil ? .some(rule.endAfterOccurrences!) : .null,
            endDate: rule.endDate != nil ? .some(iso8601String(from: rule.endDate!)) : .null
        )
    }
}
