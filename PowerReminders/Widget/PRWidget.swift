import WidgetKit
import SwiftUI
import PRCore

// MARK: - Timeline Provider

struct PRWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(
            date: Date(),
            reminders: [
                WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
                WidgetReminder(id: UUID(), title: "Call mom", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false)
            ],
            totalUpcomingCount: 5,
            overdueCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        let entry = buildEntry(for: context.family)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let entry = buildEntry(for: context.family)

        // Refresh every 15 minutes or when the next upcoming reminder is due
        let nextRefresh: Date
        let upcomingReminders = entry.reminders.filter { !$0.isOverdue }
        if let firstDue = upcomingReminders.first?.dueAt, firstDue > Date() {
            nextRefresh = min(firstDue, Date().addingTimeInterval(15 * 60))
        } else {
            nextRefresh = Date().addingTimeInterval(15 * 60)
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func buildEntry(for family: WidgetFamily) -> ReminderEntry {
        let allReminders = WidgetDataService.shared.loadReminders()
        let now = Date()

        // Separate upcoming and overdue
        let upcoming = allReminders.filter { !$0.isOverdue && $0.dueAt >= now }
            .sorted { $0.dueAt < $1.dueAt }
        let overdue = allReminders.filter { $0.isOverdue || $0.dueAt < now }
            .sorted { $0.dueAt > $1.dueAt } // Most recently overdue first

        let limit = widgetLimit(for: family)

        // For display: show upcoming first, then overdue if space allows
        var displayReminders: [WidgetReminder] = []
        displayReminders.append(contentsOf: upcoming.prefix(limit))

        // If we have space and there are overdue reminders, add them
        if displayReminders.count < limit && !overdue.isEmpty {
            let remaining = limit - displayReminders.count
            displayReminders.append(contentsOf: overdue.prefix(remaining))
        }

        return ReminderEntry(
            date: now,
            reminders: displayReminders,
            totalUpcomingCount: upcoming.count,
            overdueCount: overdue.count
        )
    }

    private func widgetLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 3
        case .systemLarge: return 6
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 1
        case .systemExtraLarge: return 8
        @unknown default: return 3
        }
    }
}

// MARK: - Entry

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminder]
    let totalUpcomingCount: Int
    let overdueCount: Int
}

// Use the shared WidgetReminder type from PRCore
typealias WidgetReminder = WidgetDataService.WidgetReminder

// MARK: - Widget Views

struct PRWidgetSmallView: View {
    let entry: ReminderEntry

    private var totalCount: Int {
        entry.totalUpcomingCount + entry.overdueCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.overdueCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .foregroundStyle(entry.overdueCount > 0 ? .red : .blue)
                Text("PR")
                    .font(.caption.weight(.semibold))
                Spacer()
                if totalCount > 1 {
                    Text("+\(totalCount - 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let reminder = entry.reminders.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    Text(formatTime(reminder.dueAt, isOverdue: reminder.isOverdue))
                        .font(.caption)
                        .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                }
            } else {
                Spacer()
                Text("All clear!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()
        }
        .padding()
    }
}

struct PRWidgetMediumView: View {
    let entry: ReminderEntry

    private var headerText: String {
        if entry.overdueCount > 0 && entry.totalUpcomingCount > 0 {
            return "Reminders"
        } else if entry.overdueCount > 0 {
            return "Overdue"
        } else {
            return "Upcoming"
        }
    }

    private var totalCount: Int {
        entry.totalUpcomingCount + entry.overdueCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.overdueCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .foregroundStyle(entry.overdueCount > 0 ? .red : .blue)
                Text(headerText)
                    .font(.caption.weight(.semibold))
                Spacer()
                if totalCount > 0 {
                    Text("\(totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if entry.reminders.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("All clear!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                ForEach(entry.reminders) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct PRWidgetLargeView: View {
    let entry: ReminderEntry

    private var headerText: String {
        if entry.overdueCount > 0 {
            return "Reminders"
        } else {
            return "Upcoming"
        }
    }

    private var totalCount: Int {
        entry.totalUpcomingCount + entry.overdueCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.overdueCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .foregroundStyle(entry.overdueCount > 0 ? .red : .blue)
                Text(headerText)
                    .font(.headline)
                Spacer()
                if totalCount > entry.reminders.count {
                    Text("+\(totalCount - entry.reminders.count) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            if entry.reminders.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("All clear!")
                            .font(.title3)
                        Text("No upcoming reminders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.reminders) { reminder in
                    ReminderRow(reminder: reminder)
                    if reminder.id != entry.reminders.last?.id {
                        Divider()
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}

struct ReminderRow: View {
    let reminder: WidgetReminder

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(priorityColor(reminder.priority, isOverdue: reminder.isOverdue))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(formatTime(reminder.dueAt, isOverdue: reminder.isOverdue))
                    .font(.caption2)
                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func priorityColor(_ priority: Int, isOverdue: Bool) -> Color {
        if isOverdue {
            return .red
        }
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
}

// MARK: - Lock Screen Widgets

struct PRAccessoryCircularView: View {
    let entry: ReminderEntry

    private var totalCount: Int {
        entry.totalUpcomingCount + entry.overdueCount
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.overdueCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 12))
                Text("\(totalCount)")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

struct PRAccessoryRectangularView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let reminder = entry.reminders.first {
                Text(reminder.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(formatTime(reminder.dueAt, isOverdue: reminder.isOverdue))
                    .font(.caption)
                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
            } else {
                Text("All clear!")
                    .font(.headline)
            }
        }
    }
}

struct PRAccessoryInlineView: View {
    let entry: ReminderEntry

    var body: some View {
        if let reminder = entry.reminders.first {
            if reminder.isOverdue {
                Text("\(reminder.title) • Overdue")
            } else {
                Text("\(reminder.title) • \(formatTime(reminder.dueAt))")
            }
        } else {
            Text("No reminders")
        }
    }
}

// MARK: - Main Widget Entry View

struct PRWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ReminderEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PRWidgetSmallView(entry: entry)
        case .systemMedium:
            PRWidgetMediumView(entry: entry)
        case .systemLarge:
            PRWidgetLargeView(entry: entry)
        case .accessoryCircular:
            PRAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            PRAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            PRAccessoryInlineView(entry: entry)
        case .systemExtraLarge:
            PRWidgetLargeView(entry: entry)
        @unknown default:
            PRWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct PRWidget: Widget {
    let kind: String = "PRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PRWidgetProvider()) { entry in
            PRWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("PR Reminders")
        .description("View your upcoming reminders at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Widget Bundle

@main
struct PRWidgetBundle: WidgetBundle {
    var body: some Widget {
        PRWidget()
    }
}

// MARK: - Helpers

private func formatTime(_ date: Date, isOverdue: Bool = false) -> String {
    let now = Date()

    // If overdue, show relative time
    if isOverdue || date < now {
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m overdue"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h overdue"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d overdue"
        }
    }

    let formatter = DateFormatter()
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    } else if calendar.isDateInTomorrow(date) {
        formatter.dateFormat = "'Tomorrow' h:mm a"
        return formatter.string(from: date)
    } else {
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    PRWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        reminders: [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false)
        ],
        totalUpcomingCount: 5,
        overdueCount: 0
    )
}

#Preview(as: .systemMedium) {
    PRWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        reminders: [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Team standup", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Doctor appointment", dueAt: Date().addingTimeInterval(14400), priority: 1, isOverdue: false)
        ],
        totalUpcomingCount: 5,
        overdueCount: 1
    )
}

#Preview("With Overdue", as: .systemMedium) {
    PRWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        reminders: [
            WidgetReminder(id: UUID(), title: "Call dentist", dueAt: Date().addingTimeInterval(-3600), priority: 3, isOverdue: true),
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Team standup", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false)
        ],
        totalUpcomingCount: 2,
        overdueCount: 1
    )
}

#Preview(as: .systemLarge) {
    PRWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        reminders: [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Team standup", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Doctor appointment", dueAt: Date().addingTimeInterval(14400), priority: 1, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Pick up kids", dueAt: Date().addingTimeInterval(18000), priority: 3, isOverdue: false)
        ],
        totalUpcomingCount: 8,
        overdueCount: 0
    )
}

#Preview(as: .accessoryCircular) {
    PRWidget()
} timeline: {
    ReminderEntry(
        date: .now,
        reminders: [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false)
        ],
        totalUpcomingCount: 5,
        overdueCount: 2
    )
}
