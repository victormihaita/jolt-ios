import SwiftUI
import PRModels
import PRNetworking
import PRSync
import ApolloAPI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var hasCompletedOnboarding: Bool = false

    // Personalization
    @Published var selectedCategories: Set<String> = []
    @Published var reminderFrequency: String?

    // Reminder creation
    @Published var reminderInput: String = ""
    @Published var parsedReminder: ParsedReminder?
    @Published var pendingReminder: PendingOnboardingReminder?

    // Notifications
    @Published var userDeclinedNotifications: Bool = false
    @Published var notificationsGranted: Bool = false

    // Persistence keys
    private let stepKey = "onboarding_current_step"
    private let completedKey = "onboarding_completed"
    private let pendingReminderKey = "onboarding_pending_reminder"
    private let categoriesKey = "onboarding_categories"
    private let frequencyKey = "onboarding_frequency"
    private let declinedNotificationsKey = "onboarding_declined_notifications"

    init() {
        loadPersistedState()
    }

    // MARK: - Persistence

    func loadPersistedState() {
        let defaults = UserDefaults.standard
        currentStep = OnboardingStep(rawValue: defaults.integer(forKey: stepKey)) ?? .welcome
        hasCompletedOnboarding = defaults.bool(forKey: completedKey)
        userDeclinedNotifications = defaults.bool(forKey: declinedNotificationsKey)
        reminderFrequency = defaults.string(forKey: frequencyKey)

        if let data = defaults.data(forKey: pendingReminderKey),
           let reminder = try? JSONDecoder().decode(PendingOnboardingReminder.self, from: data) {
            pendingReminder = reminder
        }

        if let cats = defaults.stringArray(forKey: categoriesKey) {
            selectedCategories = Set(cats)
        }
    }

    func persistState() {
        let defaults = UserDefaults.standard
        defaults.set(currentStep.rawValue, forKey: stepKey)
        defaults.set(hasCompletedOnboarding, forKey: completedKey)
        defaults.set(userDeclinedNotifications, forKey: declinedNotificationsKey)
        defaults.set(Array(selectedCategories), forKey: categoriesKey)
        defaults.set(reminderFrequency, forKey: frequencyKey)

        if let reminder = pendingReminder,
           let data = try? JSONEncoder().encode(reminder) {
            defaults.set(data, forKey: pendingReminderKey)
        }
    }

    // MARK: - Navigation

    func advanceToStep(_ step: OnboardingStep) {
        withAnimation(.smooth) {
            currentStep = step
        }
        persistState()
    }

    func nextStep() {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex + 1 < allSteps.count else { return }
        advanceToStep(allSteps[currentIndex + 1])
    }

    // MARK: - Reminder Parsing

    func parseInput(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parsedReminder = nil
        } else {
            parsedReminder = NaturalLanguageParser.parse(text)
        }
    }

    func saveReminderLocally() {
        guard let parsed = parsedReminder else { return }
        pendingReminder = PendingOnboardingReminder(
            rawInput: reminderInput,
            parsedTitle: parsed.title,
            dueDate: parsed.dueDate,
            hasSpecificTime: parsed.hasSpecificTime,
            priority: parsed.priority.rawValue,
            recurrenceFrequency: parsed.recurrence?.frequency.rawValue,
            recurrenceInterval: parsed.recurrence?.interval,
            recurrenceDaysOfWeek: parsed.recurrence?.daysOfWeek
        )
        persistState()
    }

    // MARK: - Notifications

    func requestNotificationPermission() async {
        let granted = await NotificationService.shared.requestAuthorizationIfNeeded()
        notificationsGranted = granted
    }

    // MARK: - Backend Sync

    func syncPendingReminderToBackend() async {
        guard let pending = pendingReminder else { return }

        do {
            var recurrenceInput: GraphQLNullable<PRAPI.RecurrenceRuleInput> = .null
            if let freqStr = pending.recurrenceFrequency,
               let frequency = Frequency(rawValue: freqStr) {
                let gqlFreq: GraphQLEnum<PRAPI.Frequency>
                switch frequency {
                case .hourly: gqlFreq = .init(.hourly)
                case .daily: gqlFreq = .init(.daily)
                case .weekly: gqlFreq = .init(.weekly)
                case .monthly: gqlFreq = .init(.monthly)
                case .yearly: gqlFreq = .init(.yearly)
                }
                recurrenceInput = .some(PRAPI.RecurrenceRuleInput(
                    frequency: gqlFreq,
                    interval: pending.recurrenceInterval ?? 1,
                    daysOfWeek: pending.recurrenceDaysOfWeek.map { .some($0) } ?? .null,
                    dayOfMonth: .null,
                    monthOfYear: .null,
                    endAfterOccurrences: .null,
                    endDate: .null
                ))
            }

            let gqlPriority: GraphQLEnum<PRAPI.Priority>
            switch pending.priority {
            case 3: gqlPriority = .init(.high)
            case 2: gqlPriority = .init(.normal)
            case 1: gqlPriority = .init(.low)
            default: gqlPriority = .init(.none)
            }

            let title = pending.parsedTitle.isEmpty ? pending.rawInput : pending.parsedTitle

            let dueAtStr: GraphQLNullable<String>
            if let date = pending.dueDate {
                dueAtStr = .some(ISO8601DateFormatter().string(from: date))
            } else {
                dueAtStr = .null
            }

            let input = PRAPI.CreateReminderInput(
                listId: .null,
                title: title,
                notes: .null,
                priority: .some(gqlPriority),
                dueAt: dueAtStr,
                allDay: pending.dueDate != nil ? .some(!pending.hasSpecificTime) : .null,
                recurrenceRule: recurrenceInput,
                isAlarm: .null,
                soundId: .null
            )

            let mutation = PRAPI.CreateReminderMutation(input: input)
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            SyncEngine.shared.refetch()
        } catch {
            print("Failed to sync onboarding reminder: \(error)")
            // Non-fatal: SyncEngine will pick it up on next sync
        }

        // Clear pending reminder
        pendingReminder = nil
        UserDefaults.standard.removeObject(forKey: pendingReminderKey)
    }

    // MARK: - Completion

    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = .completed
        persistState()
    }
}
