import SwiftUI

struct InAppNotificationBanner: View {
    let title: String
    let subtitle: String
    let reminderID: UUID
    let dueAt: Date?
    let soundID: String?
    let isAlarm: Bool
    let isPremium: Bool

    let onComplete: () -> Void
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void
    let onTap: () -> Void
    let onShowPaywall: () -> Void
    var initialSnoozeExpanded: Bool = false

    @State private var showSnoozeOptions = false
    @State private var showCustomPicker = false
    @State private var customHours = 0
    @State private var customMinutes = 15

    private let quickSnoozeOptions = [5, 15, 30, 60]

    var body: some View {
        VStack(spacing: 0) {
            // Main banner content
            bannerHeader

            // Action buttons
            if isAlarm {
                alarmActionButtons
            } else {
                reminderActionButtons
            }

            // Snooze section (expandable)
            if showSnoozeOptions {
                snoozeSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                .strokeBorder(
                    isAlarm ? Theme.Colors.error.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .prShadow(Theme.Shadows.strong)
        .onAppear {
            if initialSnoozeExpanded {
                withAnimation(.snappy) {
                    showSnoozeOptions = true
                }
            }
        }
    }

    // MARK: - Banner Header

    private var bannerHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: isAlarm ? "alarm.fill" : "bell.fill")
                    .font(.title2)
                    .foregroundStyle(iconBackgroundColor)
                    .symbolEffect(.pulse, isActive: isAlarm)
            }

            // Text content
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let dueAt = dueAt {
                    Text(formattedTime(dueAt))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Dismiss X button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
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
    }

    // MARK: - Alarm Actions

    private var alarmActionButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Complete button
            Button(action: onComplete) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete")
                }
                .font(Theme.Typography.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            }
            .buttonStyle(.plain)

            // Snooze button
            snoozeToggleButton
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Reminder Actions

    private var reminderActionButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Complete button
            Button(action: onComplete) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete")
                }
                .font(Theme.Typography.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            }
            .buttonStyle(.plain)

            // Snooze button
            snoozeToggleButton
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Shared Snooze Toggle

    private var snoozeToggleButton: some View {
        Button {
            withAnimation(.snappy) {
                showSnoozeOptions.toggle()
                if !showSnoozeOptions {
                    showCustomPicker = false
                }
            }
            Haptics.light()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "clock.arrow.circlepath")
                Text("Snooze")
                Image(systemName: showSnoozeOptions ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .font(Theme.Typography.callout.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.warning)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Snooze Section

    private var snoozeSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Quick snooze options (free for all)
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(quickSnoozeOptions, id: \.self) { minutes in
                    Button {
                        onSnooze(minutes)
                    } label: {
                        Text(formatSnoozeTime(minutes))
                            .font(Theme.Typography.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm + 2)
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom time toggle
            Button {
                withAnimation(.snappy) {
                    showCustomPicker.toggle()
                }
                Haptics.light()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: isPremium ? "timer" : "lock.fill")
                        .font(.caption)
                    Text("Custom time...")
                        .font(Theme.Typography.subheadline.weight(.medium))
                }
                .foregroundStyle(isPremium ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
            }
            .buttonStyle(.plain)

            // Custom picker or premium upsell
            if showCustomPicker {
                if isPremium {
                    customTimePicker
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    premiumSnoozeUpsell
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Custom Time Picker (Premium)

    private var customTimePicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                // Hours picker
                VStack(spacing: 2) {
                    Text("Hours")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                    Picker("Hours", selection: $customHours) {
                        ForEach(0...12, id: \.self) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }

                // Minutes picker
                VStack(spacing: 2) {
                    Text("Minutes")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.secondary)
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach(0...59, id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }
            }

            // Confirm button
            Button {
                let totalMinutes = (customHours * 60) + customMinutes
                guard totalMinutes > 0 else { return }
                onSnooze(totalMinutes)
            } label: {
                Text(customSnoozeLabel)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm + 2)
                    .background(totalCustomMinutes > 0 ? Theme.Colors.warning : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
            }
            .buttonStyle(.plain)
            .disabled(totalCustomMinutes == 0)
        }
    }

    // MARK: - Premium Upsell

    private var premiumSnoozeUpsell: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("Custom Snooze")
                    .font(Theme.Typography.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            Text("Snooze for any duration — set exact hours and minutes")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onShowPaywall) {
                Text("Upgrade to Premium")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm + 2)
                    .background(Theme.Colors.premiumGradient)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.secondaryBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    // MARK: - Helpers

    private var iconBackgroundColor: Color {
        isAlarm ? Theme.Colors.error : Theme.Colors.primary
    }

    private var totalCustomMinutes: Int {
        (customHours * 60) + customMinutes
    }

    private var customSnoozeLabel: String {
        let total = totalCustomMinutes
        if total == 0 {
            return "Select a time"
        }
        if customHours > 0 && customMinutes > 0 {
            return "Snooze for \(customHours)h \(customMinutes)m"
        } else if customHours > 0 {
            return "Snooze for \(customHours)h"
        } else {
            return "Snooze for \(customMinutes)m"
        }
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

        VStack(spacing: Theme.Spacing.md) {
            InAppNotificationBanner(
                title: "Call Mom",
                subtitle: "Don't forget to call mom today",
                reminderID: UUID(),
                dueAt: Date(),
                soundID: "ambient.wav",
                isAlarm: false,
                isPremium: true,
                onComplete: { print("Complete tapped") },
                onSnooze: { minutes in print("Snooze \(minutes)m") },
                onDismiss: { print("Dismiss tapped") },
                onTap: { print("Banner tapped") },
                onShowPaywall: { print("Show paywall") }
            )
            .padding(.horizontal, Theme.Spacing.md)

            InAppNotificationBanner(
                title: "Wake Up!",
                subtitle: "Morning alarm",
                reminderID: UUID(),
                dueAt: Date(),
                soundID: nil,
                isAlarm: true,
                isPremium: false,
                onComplete: { print("Complete tapped") },
                onSnooze: { minutes in print("Snooze \(minutes)m") },
                onDismiss: { print("Stop tapped") },
                onTap: { print("Banner tapped") },
                onShowPaywall: { print("Show paywall") }
            )
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
        }
        .padding(.top, 60)
    }
}
