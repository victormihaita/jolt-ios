import ActivityKit
import SwiftUI
import WidgetKit
import AppIntents

/// Live Activity widget that displays a countdown on the lock screen and Dynamic Island
/// when a reminder is approaching its due time.
struct ReminderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReminderActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner View
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(priorityColor(
                                context.state.priority,
                                isOverdue: context.state.isOverdue
                            ))
                            .font(.title3)

                        priorityLabel(context.state.priority, isOverdue: context.state.isOverdue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    countdownView(dueAt: context.state.dueAt, isOverdue: context.state.isOverdue)
                        .font(.title3.monospacedDigit())
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.reminderTitle)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        Button(intent: CompleteReminderIntent(reminderID: context.attributes.reminderId)) {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SnoozeReminderIntent(reminderID: context.attributes.reminderId)) {
                            Label("Snooze", systemImage: "clock.arrow.circlepath")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Image(systemName: "bell.fill")
                    .foregroundStyle(priorityColor(
                        context.state.priority,
                        isOverdue: context.state.isOverdue
                    ))
                    .font(.body)
            } compactTrailing: {
                // MARK: - Compact Trailing
                countdownView(dueAt: context.state.dueAt, isOverdue: context.state.isOverdue)
                    .font(.body.monospacedDigit())
            } minimal: {
                // MARK: - Minimal
                Image(systemName: "bell.fill")
                    .foregroundStyle(priorityColor(
                        context.state.priority,
                        isOverdue: context.state.isOverdue
                    ))
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ReminderActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor(context.state.priority, isOverdue: context.state.isOverdue))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.reminderTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if context.state.isOverdue {
                        Text("Overdue")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } else {
                        Text(context.state.dueAt, style: .relative)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Countdown or overdue badge
            if context.state.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            } else {
                Text(context.state.dueAt, style: .timer)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(priorityColor(context.state.priority, isOverdue: false))
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 60)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func countdownView(dueAt: Date, isOverdue: Bool) -> some View {
        if isOverdue {
            Text("Overdue")
                .foregroundStyle(.red)
                .fontWeight(.semibold)
        } else {
            Text(dueAt, style: .timer)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func priorityLabel(_ priority: Int, isOverdue: Bool) -> some View {
        if isOverdue {
            Text("OVERDUE")
                .foregroundStyle(.red)
                .fontWeight(.bold)
        } else {
            switch priority {
            case 3:
                Text("HIGH")
                    .foregroundStyle(.red)
            case 2:
                Text("NORMAL")
                    .foregroundStyle(.orange)
            case 1:
                Text("LOW")
                    .foregroundStyle(.blue)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Priority Color

    /// Returns the color associated with a priority level, matching the widget color scheme.
    /// - Parameters:
    ///   - priority: The raw priority value (0-3).
    ///   - isOverdue: Whether the reminder is past due.
    /// - Returns: The corresponding color.
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
