import Foundation
import PRModels

struct ParsedReminder {
    var title: String
    var dueDate: Date?
    var priority: Priority
    var recurrence: RecurrenceRule?
    var listName: String?
    var tags: [String]
    var suggestedListId: UUID?
    var hasSpecificTime: Bool

    init(
        title: String,
        dueDate: Date? = nil,
        priority: Priority = .none,
        recurrence: RecurrenceRule? = nil,
        listName: String? = nil,
        tags: [String] = [],
        suggestedListId: UUID? = nil,
        hasSpecificTime: Bool = false
    ) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.recurrence = recurrence
        self.listName = listName
        self.tags = tags
        self.suggestedListId = suggestedListId
        self.hasSpecificTime = hasSpecificTime
    }
}

class NaturalLanguageParser {
    static func parse(_ input: String) -> ParsedReminder {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var dueDate: Date?
        var dueTime: Date?
        var priority: Priority = .none
        var recurrence: RecurrenceRule?
        var tags: [String] = []
        let calendar = Calendar.current

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

        // Extract time first (so we can combine with date later)
        (dueTime, text) = parseAbsoluteTime(from: text)

        // Extract relative time patterns (tomorrow, next week, monday, etc.)
        (dueDate, text) = parseRelativeTime(from: text)

        // Extract absolute date patterns (on 24 dec, on 24.12, etc.)
        if dueDate == nil {
            (dueDate, text) = parseAbsoluteDate(from: text)
        }

        // Combine date and time if both are present
        if let date = dueDate, let time = dueTime {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            dueDate = calendar.date(from: dateComponents)
        } else if dueDate == nil && dueTime != nil {
            // Only time specified, use today's date
            dueDate = dueTime
        }

        // Extract recurrence patterns
        (recurrence, text) = parseRecurrence(from: text)

        // Clean up the title
        var title = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        // Remove trailing/leading "on" if present after date extraction
        if title.lowercased().hasPrefix("on ") {
            title = String(title.dropFirst(3))
        }
        if title.lowercased().hasSuffix(" on") {
            title = String(title.dropLast(3))
        }

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
        let calendar = Calendar.current

        // "in X minutes/hours/days"
        if let match = mutableText.range(of: #"in (\d+)\s*(min(?:ute)?s?|hours?|days?|weeks?)"#, options: .regularExpression) {
            let matchedText = String(mutableText[match])
            let components = matchedText.components(separatedBy: .whitespaces)
            if components.count >= 2, let number = Int(components[1]) {
                let unit = components.last?.lowercased() ?? ""
                var date = Date()

                if unit.starts(with: "min") {
                    date = calendar.date(byAdding: .minute, value: number, to: date) ?? date
                } else if unit.starts(with: "hour") {
                    date = calendar.date(byAdding: .hour, value: number, to: date) ?? date
                } else if unit.starts(with: "day") {
                    date = calendar.date(byAdding: .day, value: number, to: date) ?? date
                } else if unit.starts(with: "week") {
                    date = calendar.date(byAdding: .weekOfYear, value: number, to: date) ?? date
                }

                mutableText.removeSubrange(match)
                return (date, mutableText)
            }
        }

        // "tomorrow"
        if let match = mutableText.range(of: #"\btomorrow\b"#, options: [.regularExpression, .caseInsensitive]) {
            mutableText.removeSubrange(match)
            let date = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))
            return (date, mutableText)
        }

        // "today"
        if let match = mutableText.range(of: #"\btoday\b"#, options: [.regularExpression, .caseInsensitive]) {
            mutableText.removeSubrange(match)
            return (Date(), mutableText)
        }

        // "next week"
        if let match = mutableText.range(of: #"\bnext week\b"#, options: [.regularExpression, .caseInsensitive]) {
            mutableText.removeSubrange(match)
            let date = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
            return (date, mutableText)
        }

        // "next Monday", "next Wednesday", etc.
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if let match = mutableText.range(of: #"\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, options: [.regularExpression, .caseInsensitive]) {
            let matchedText = String(mutableText[match]).lowercased()
            for (index, day) in dayNames.enumerated() {
                if matchedText.contains(day) {
                    let currentDay = calendar.component(.weekday, from: Date()) - 1
                    var daysToAdd = index - currentDay
                    if daysToAdd <= 0 {
                        daysToAdd += 7
                    }
                    // "next" means at least 7 days out
                    daysToAdd += 7
                    mutableText.removeSubrange(match)
                    let date = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: Date()))
                    return (date, mutableText)
                }
            }
        }

        // Day names without "next" (e.g., "monday", "wednesday")
        if let match = mutableText.range(of: #"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, options: [.regularExpression, .caseInsensitive]) {
            let dayName = String(mutableText[match]).lowercased()
            if let targetDay = dayNames.firstIndex(of: dayName) {
                let currentDay = calendar.component(.weekday, from: Date()) - 1
                var daysToAdd = targetDay - currentDay
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                mutableText.removeSubrange(match)
                let date = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: Date()))
                return (date, mutableText)
            }
        }

        return (nil, mutableText)
    }

    // MARK: - Absolute Date Parsing

    private static func parseAbsoluteDate(from text: String) -> (Date?, String) {
        var mutableText = text
        let calendar = Calendar.current

        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]
        let monthAbbreviations = ["jan", "feb", "mar", "apr", "may", "jun",
                                  "jul", "aug", "sep", "oct", "nov", "dec"]

        // "on 24 of december", "on 24th of december", "on 24 december", "on 24th december"
        let fullMonthPattern = #"\b(?:on\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(january|february|march|april|may|june|july|august|september|october|november|december)\b"#
        if let regex = try? NSRegularExpression(pattern: fullMonthPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: mutableText, options: [], range: NSRange(mutableText.startIndex..., in: mutableText)) {

            if let dayRange = Range(match.range(at: 1), in: mutableText),
               let monthRange = Range(match.range(at: 2), in: mutableText) {
                let day = Int(mutableText[dayRange]) ?? 1
                let monthName = String(mutableText[monthRange]).lowercased()

                if let monthIndex = monthNames.firstIndex(of: monthName) {
                    if let fullRange = Range(match.range, in: mutableText) {
                        mutableText.removeSubrange(fullRange)
                    }

                    var components = calendar.dateComponents([.year], from: Date())
                    components.month = monthIndex + 1
                    components.day = day

                    // If the date is in the past, use next year
                    if let date = calendar.date(from: components), date < Date() {
                        components.year = (components.year ?? 0) + 1
                    }

                    return (calendar.date(from: components), mutableText)
                }
            }
        }

        // "on 24 dec", "on 24th dec"
        let abbrevMonthPattern = #"\b(?:on\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\b"#
        if let regex = try? NSRegularExpression(pattern: abbrevMonthPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: mutableText, options: [], range: NSRange(mutableText.startIndex..., in: mutableText)) {

            if let dayRange = Range(match.range(at: 1), in: mutableText),
               let monthRange = Range(match.range(at: 2), in: mutableText) {
                let day = Int(mutableText[dayRange]) ?? 1
                let monthAbbrev = String(mutableText[monthRange]).lowercased()

                if let monthIndex = monthAbbreviations.firstIndex(of: monthAbbrev) {
                    if let fullRange = Range(match.range, in: mutableText) {
                        mutableText.removeSubrange(fullRange)
                    }

                    var components = calendar.dateComponents([.year], from: Date())
                    components.month = monthIndex + 1
                    components.day = day

                    // If the date is in the past, use next year
                    if let date = calendar.date(from: components), date < Date() {
                        components.year = (components.year ?? 0) + 1
                    }

                    return (calendar.date(from: components), mutableText)
                }
            }
        }

        // "on 24.12", "on 24/12", "on 24-12" (day.month format)
        let numericDatePattern = #"\b(?:on\s+)?(\d{1,2})[./\-](\d{1,2})\b"#
        if let regex = try? NSRegularExpression(pattern: numericDatePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: mutableText, options: [], range: NSRange(mutableText.startIndex..., in: mutableText)) {

            if let dayRange = Range(match.range(at: 1), in: mutableText),
               let monthRange = Range(match.range(at: 2), in: mutableText) {
                let day = Int(mutableText[dayRange]) ?? 1
                let month = Int(mutableText[monthRange]) ?? 1

                if day >= 1 && day <= 31 && month >= 1 && month <= 12 {
                    if let fullRange = Range(match.range, in: mutableText) {
                        mutableText.removeSubrange(fullRange)
                    }

                    var components = calendar.dateComponents([.year], from: Date())
                    components.month = month
                    components.day = day

                    // If the date is in the past, use next year
                    if let date = calendar.date(from: components), date < Date() {
                        components.year = (components.year ?? 0) + 1
                    }

                    return (calendar.date(from: components), mutableText)
                }
            }
        }

        return (nil, mutableText)
    }

    // MARK: - Absolute Time Parsing

    private static func parseAbsoluteTime(from text: String) -> (Date?, String) {
        var mutableText = text
        let calendar = Calendar.current

        // "at 4pm", "at 4 pm", "at 4:30pm", "at 16:00", "at 16", "at 4 afternoon", "at 4 morning", "at 4 evening"
        let timePattern = #"\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|morning|afternoon|evening|night)?\b"#

        if let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: mutableText, options: [], range: NSRange(mutableText.startIndex..., in: mutableText)) {

            if let hourRange = Range(match.range(at: 1), in: mutableText) {
                var hour = Int(mutableText[hourRange]) ?? 0
                var minute = 0

                if let minuteRange = Range(match.range(at: 2), in: mutableText) {
                    minute = Int(mutableText[minuteRange]) ?? 0
                }

                // Handle AM/PM and time of day words
                if let periodRange = Range(match.range(at: 3), in: mutableText) {
                    let period = String(mutableText[periodRange]).lowercased()
                    switch period {
                    case "pm", "afternoon", "evening":
                        if hour < 12 {
                            hour += 12
                        }
                    case "am", "morning":
                        if hour == 12 {
                            hour = 0
                        }
                    case "night":
                        // Night could be late evening (8pm+) or late night
                        if hour < 12 && hour >= 1 && hour <= 6 {
                            // Early morning hours like "at 2 night" means 2am
                            // Keep as is
                        } else if hour < 12 {
                            hour += 12
                        }
                    default:
                        break
                    }
                } else if hour >= 1 && hour <= 12 {
                    // No period specified and hour is ambiguous (1-12)
                    // If hour is less than current hour and in reasonable range, assume PM
                    let currentHour = calendar.component(.hour, from: Date())
                    if hour < currentHour && hour < 12 {
                        // Could be PM, but leave as-is for now (user can be explicit)
                    }
                }
                // Hours > 12 are already in 24-hour format

                if let fullRange = Range(match.range, in: mutableText) {
                    let matchedText = String(mutableText[fullRange])
                    // Only process if it looks like a time (has "at" or period indicator)
                    if matchedText.lowercased().contains("at") ||
                       matchedText.lowercased().contains("am") ||
                       matchedText.lowercased().contains("pm") ||
                       matchedText.lowercased().contains("morning") ||
                       matchedText.lowercased().contains("afternoon") ||
                       matchedText.lowercased().contains("evening") ||
                       matchedText.lowercased().contains("night") ||
                       matchedText.contains(":") {
                        mutableText.removeSubrange(fullRange)

                        var components = calendar.dateComponents([.year, .month, .day], from: Date())
                        components.hour = hour
                        components.minute = minute
                        let date = calendar.date(from: components)
                        return (date, mutableText)
                    }
                }
            }
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
