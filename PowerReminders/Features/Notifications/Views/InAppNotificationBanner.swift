import SwiftUI

struct InAppNotificationBanner: View {
    let title: String
    let subtitle: String
    let reminderID: UUID
    let dueAt: Date?
    let soundID: String?
    let isAlarm: Bool

    let onComplete: () -> Void
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void

    @State private var showSnoozeOptions = false

    private let snoozeOptions = [5, 15, 30, 60]

    var body: some View {
        VStack(spacing: 0) {
            // Main banner content
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: isAlarm ? "alarm.fill" : "bell.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.primary)
                }

                // Text content
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if let dueAt = dueAt {
                        Text(formattedTime(dueAt))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Dismiss X button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.sm) {
                // Complete button
                Button(action: onComplete) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .font(Theme.Typography.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm + 2)
                    .background(Theme.Colors.success)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }
                .buttonStyle(.plain)

                // Snooze button
                Button {
                    withAnimation(.snappy) {
                        showSnoozeOptions.toggle()
                    }
                    Haptics.light()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Snooze")
                        Image(systemName: showSnoozeOptions ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .font(Theme.Typography.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm + 2)
                    .background(Theme.Colors.warning)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.md)

            // Snooze options (expandable)
            if showSnoozeOptions {
                snoozeOptionsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
        .prShadow(Theme.Shadows.strong)
    }

    private var snoozeOptionsView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(snoozeOptions, id: \.self) { minutes in
                Button {
                    onSnooze(minutes)
                } label: {
                    Text(formatSnoozeTime(minutes))
                        .font(Theme.Typography.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Due " + formatter.string(from: date)
    }

    private func formatSnoozeTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        VStack {
            InAppNotificationBanner(
                title: "Call Mom",
                subtitle: "Don't forget to call mom today",
                reminderID: UUID(),
                dueAt: Date(),
                soundID: "ambient.wav",
                isAlarm: false,
                onComplete: { print("Complete tapped") },
                onSnooze: { minutes in print("Snooze \(minutes)m") },
                onDismiss: { print("Dismiss tapped") },
                onTap: { print("Banner tapped") }
            )
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
        }
        .padding(.top, 60)
    }
}
