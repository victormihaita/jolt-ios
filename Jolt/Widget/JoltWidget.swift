import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct JoltWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(date: Date(), reminders: [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Call mom", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        let entry = ReminderEntry(date: Date(), reminders: fetchReminders(limit: widgetLimit(for: context.family)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let reminders = fetchReminders(limit: widgetLimit(for: context.family))
        let entry = ReminderEntry(date: Date(), reminders: reminders)

        // Refresh every 15 minutes or when the next reminder is due
        let nextRefresh: Date
        if let firstDue = reminders.first?.dueAt, firstDue > Date() {
            nextRefresh = min(firstDue, Date().addingTimeInterval(15 * 60))
        } else {
            nextRefresh = Date().addingTimeInterval(15 * 60)
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func widgetLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 3
        case .systemLarge: return 6
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 1
        @unknown default: return 3
        }
    }

    private func fetchReminders(limit: Int) -> [WidgetReminder] {
        // TODO: Fetch from shared SwiftData container or App Group
        // For now, return sample data
        return [
            WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Team standup", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false),
            WidgetReminder(id: UUID(), title: "Doctor appointment", dueAt: Date().addingTimeInterval(14400), priority: 3, isOverdue: false)
        ].prefix(limit).map { $0 }
    }
}

// MARK: - Entry

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminder]
}

struct WidgetReminder: Identifiable {
    let id: UUID
    let title: String
    let dueAt: Date
    let priority: Int
    let isOverdue: Bool
}

// MARK: - Widget Views

struct JoltWidgetSmallView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.blue)
                Text("Jolt")
                    .font(.caption.weight(.semibold))
                Spacer()
            }

            if let reminder = entry.reminders.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    Text(formatTime(reminder.dueAt))
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

struct JoltWidgetMediumView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.blue)
                Text("Upcoming")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(entry.reminders.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

struct JoltWidgetLargeView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.blue)
                Text("Today's Reminders")
                    .font(.headline)
                Spacer()
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
                        Text("No reminders for today")
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
                .fill(priorityColor(reminder.priority))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(formatTime(reminder.dueAt))
                    .font(.caption2)
                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
}

// MARK: - Lock Screen Widgets

struct JoltAccessoryCircularView: View {
    let entry: ReminderEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                Text("\(entry.reminders.count)")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

struct JoltAccessoryRectangularView: View {
    let entry: ReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let reminder = entry.reminders.first {
                Text(reminder.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(formatTime(reminder.dueAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("All clear!")
                    .font(.headline)
            }
        }
    }
}

struct JoltAccessoryInlineView: View {
    let entry: ReminderEntry

    var body: some View {
        if let reminder = entry.reminders.first {
            Text("\(reminder.title) • \(formatTime(reminder.dueAt))")
        } else {
            Text("No reminders")
        }
    }
}

// MARK: - Main Widget Entry View

struct JoltWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ReminderEntry

    var body: some View {
        switch family {
        case .systemSmall:
            JoltWidgetSmallView(entry: entry)
        case .systemMedium:
            JoltWidgetMediumView(entry: entry)
        case .systemLarge:
            JoltWidgetLargeView(entry: entry)
        case .accessoryCircular:
            JoltAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            JoltAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            JoltAccessoryInlineView(entry: entry)
        @unknown default:
            JoltWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct JoltWidget: Widget {
    let kind: String = "JoltWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JoltWidgetProvider()) { entry in
            JoltWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Jolt Reminders")
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
struct JoltWidgetBundle: WidgetBundle {
    var body: some Widget {
        JoltWidget()
    }
}

// MARK: - Helpers

private func formatTime(_ date: Date) -> String {
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
    JoltWidget()
} timeline: {
    ReminderEntry(date: .now, reminders: [
        WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false)
    ])
}

#Preview(as: .systemMedium) {
    JoltWidget()
} timeline: {
    ReminderEntry(date: .now, reminders: [
        WidgetReminder(id: UUID(), title: "Buy groceries", dueAt: Date().addingTimeInterval(3600), priority: 2, isOverdue: false),
        WidgetReminder(id: UUID(), title: "Team standup", dueAt: Date().addingTimeInterval(7200), priority: 3, isOverdue: false),
        WidgetReminder(id: UUID(), title: "Doctor appointment", dueAt: Date().addingTimeInterval(14400), priority: 1, isOverdue: false)
    ])
}
