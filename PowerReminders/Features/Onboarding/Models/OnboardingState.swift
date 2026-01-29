import Foundation
import PRModels

enum OnboardingStep: Int, Codable, CaseIterable {
    case welcome = 0
    case personalization = 1
    case createReminder = 2
    case notifications = 3
    case signIn = 4
    case paywall = 5
    case completed = 6
}

struct PendingOnboardingReminder: Codable {
    var rawInput: String
    var parsedTitle: String
    var dueDate: Date?
    var hasSpecificTime: Bool
    var priority: Int
    var recurrenceFrequency: String?
    var recurrenceInterval: Int?
    var recurrenceDaysOfWeek: [Int]?
}
