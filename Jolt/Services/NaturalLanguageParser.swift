import Foundation
import JoltModels

struct ParsedReminder {
    var title: String
    var dueDate: Date?
    var priority: Priority
    var recurrence: RecurrenceRule?
    var listName: String?
    var tags: [String]

    init(
        title: String,
        dueDate: Date? = nil,
        priority: Priority = .none,
        recurrence: RecurrenceRule? = nil,
        listName: String? = nil,
        tags: [String] = []
    ) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.recurrence = recurrence
        self.listName = listName
        self.tags = tags
    }
}

class NaturalLanguageParser {
    static func parse(_ input: String) -> ParsedReminder {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var dueDate: Date?
        var priority: Priority = .none
        var recurrence: RecurrenceRule?
        var tags: [String] = []

        // Extract tags (#tag)
        let tagPattern = #"#(\w+)"#
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches.reversed() {
                if let tagRange = Range(match.range(at: 1), in: text) {
                    let tag = String(text[tagRange]).lowercased()

                    // Check if tag is a priority
                    switch tag {
                    case "high", "urgent", "important":
                        priority = .high
                    case "normal", "medium":
                        priority = .normal
                    case "low":
                        priority = .low
                    default:
                        tags.append(tag)
                    }
                }

                // Remove the tag from the text
                if let fullRange = Range(match.range, in: text) {
                    text.removeSubrange(fullRange)
                }
            }
        }

        // Extract relative time patterns
        (dueDate, text) = parseRelativeTime(from: text)

        // Extract absolute time patterns
        if dueDate == nil {
            (dueDate, text) = parseAbsoluteTime(from: text)
        }

        // Extract recurrence patterns
        (recurrence, text) = parseRecurrence(from: text)

        // Clean up the title
        let title = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        return ParsedReminder(
            title: title.isEmpty ? input : title,
            dueDate: dueDate,
            priority: priority,
            recurrence: recurrence,
            tags: tags
        )
    }

    // MARK: - Relative Time Parsing

    private static func parseRelativeTime(from text: String) -> (Date?, String) {
        var mutableText = text

        // "in X minutes/hours/days"
        if let match = mutableText.range(of: #"in (\d+)\s*(min(?:ute)?s?|hours?|days?|weeks?)"#, options: .regularExpression) {
            let matchedText = String(mutableText[match])
            let components = matchedText.components(separatedBy: .whitespaces)
            if components.count >= 2, let number = Int(components[1]) {
                let unit = components.last?.lowercased() ?? ""
                var date = Date()

                if unit.starts(with: "min") {
                    date = Calendar.current.date(byAdding: .minute, value: number, to: date) ?? date
                } else if unit.starts(with: "hour") {
                    date = Calendar.current.date(byAdding: .hour, value: number, to: date) ?? date
                } else if unit.starts(with: "day") {
                    date = Calendar.current.date(byAdding: .day, value: number, to: date) ?? date
                } else if unit.starts(with: "week") {
                    date = Calendar.current.date(byAdding: .weekOfYear, value: number, to: date) ?? date
                }

                mutableText.removeSubrange(match)
                return (date, mutableText)
            }
        }

        // "tomorrow"
        if let match = mutableText.range(of: #"\btomorrow\b"#, options: .regularExpression) {
            mutableText.removeSubrange(match)
            let date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
            return (date, mutableText)
        }

        // "today"
        if let match = mutableText.range(of: #"\btoday\b"#, options: .regularExpression) {
            mutableText.removeSubrange(match)
            return (Date(), mutableText)
        }

        // "next week"
        if let match = mutableText.range(of: #"\bnext week\b"#, options: .regularExpression) {
            mutableText.removeSubrange(match)
            let date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
            return (date, mutableText)
        }

        // Day names
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if let match = mutableText.range(of: #"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, options: [.regularExpression, .caseInsensitive]) {
            let dayName = String(mutableText[match]).lowercased()
            if let targetDay = dayNames.firstIndex(of: dayName) {
                let currentDay = Calendar.current.component(.weekday, from: Date()) - 1
                var daysToAdd = targetDay - currentDay
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                mutableText.removeSubrange(match)
                let date = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Calendar.current.startOfDay(for: Date()))
                return (date, mutableText)
            }
        }

        return (nil, mutableText)
    }

    // MARK: - Absolute Time Parsing

    private static func parseAbsoluteTime(from text: String) -> (Date?, String) {
        var mutableText = text
        let timePattern = #"at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#

        if let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: mutableText, options: [], range: NSRange(mutableText.startIndex..., in: mutableText)) {

            var hour = 0
            var minute = 0

            if let hourRange = Range(match.range(at: 1), in: mutableText) {
                hour = Int(mutableText[hourRange]) ?? 0
            }

            if let minuteRange = Range(match.range(at: 2), in: mutableText) {
                minute = Int(mutableText[minuteRange]) ?? 0
            }

            if let ampmRange = Range(match.range(at: 3), in: mutableText) {
                let ampm = String(mutableText[ampmRange]).lowercased()
                if ampm == "pm" && hour < 12 {
                    hour += 12
                } else if ampm == "am" && hour == 12 {
                    hour = 0
                }
            }

            if let fullRange = Range(match.range, in: mutableText) {
                mutableText.removeSubrange(fullRange)
            }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            let date = Calendar.current.date(from: components)
            return (date, mutableText)
        }

        return (nil, mutableText)
    }

    // MARK: - Recurrence Parsing

    private static func parseRecurrence(from text: String) -> (RecurrenceRule?, String) {
        var mutableText = text

        let patterns: [(pattern: String, frequency: Frequency)] = [
            (#"\bevery day\b"#, .daily),
            (#"\bdaily\b"#, .daily),
            (#"\bevery week\b"#, .weekly),
            (#"\bweekly\b"#, .weekly),
            (#"\bevery month\b"#, .monthly),
            (#"\bmonthly\b"#, .monthly),
            (#"\bevery year\b"#, .yearly),
            (#"\byearly\b"#, .yearly),
            (#"\bannually\b"#, .yearly)
        ]

        for (pattern, frequency) in patterns {
            if let match = mutableText.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                mutableText.removeSubrange(match)
                return (RecurrenceRule(frequency: frequency), mutableText)
            }
        }

        // "every Monday" pattern
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if let match = mutableText.range(of: #"\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, options: [.regularExpression, .caseInsensitive]) {
            let matchedText = String(mutableText[match]).lowercased()
            for (index, day) in dayNames.enumerated() {
                if matchedText.contains(day) {
                    mutableText.removeSubrange(match)
                    return (RecurrenceRule(frequency: .weekly, daysOfWeek: [index]), mutableText)
                }
            }
        }

        return (nil, mutableText)
    }
}
