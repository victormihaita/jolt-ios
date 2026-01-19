import Foundation

public extension Date {
    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns true if this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Returns true if this date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Returns true if this date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Adds the specified number of minutes to this date
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// Adds the specified number of hours to this date
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Adds the specified number of days to this date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns a formatted string for display in reminders
    var reminderDisplayString: String {
        let formatter = DateFormatter()

        if isToday {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: self))"
        } else if isTomorrow {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow, \(formatter.string(from: self))"
        } else if Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
            return formatter.string(from: self)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: self)
        }
    }

    /// Returns a short formatted string for widgets
    var widgetDisplayString: String {
        let formatter = DateFormatter()

        if isToday {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: self)
        } else if isTomorrow {
            formatter.dateFormat = "'Tomorrow' h:mm a"
            return formatter.string(from: self)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: self)
        }
    }

    /// Returns the start of the day for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day for this date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}
