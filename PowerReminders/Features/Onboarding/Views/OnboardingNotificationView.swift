import SwiftUI

struct OnboardingNotificationView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.bounce, options: .repeating.speed(0.5))

                    Text("Never miss a reminder")
                        .font(Theme.Typography.largeTitle)
                        .multilineTextAlignment(.center)

                    Text("Get notified at exactly the right time.\nYou can always change this in Settings.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Mock notification
                MockNotificationCard(
                    title: viewModel.pendingReminder?.parsedTitle ?? "Your reminder",
                    time: formattedTime
                )
                .padding(.horizontal, Theme.Spacing.lg)
            }

            Spacer()

            // Bottom buttons
            VStack(spacing: Theme.Spacing.md) {
                Button {
                    Haptics.medium()
                    Task {
                        await viewModel.requestNotificationPermission()
                        viewModel.advanceToStep(.premiumValue)
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "bell.fill")
                        Text("Enable Notifications")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                }

                Button {
                    viewModel.userDeclinedNotifications = true
                    viewModel.advanceToStep(.premiumValue)
                } label: {
                    Text("Not Now")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 48)
        }
    }

    private var formattedTime: String {
        guard let date = viewModel.pendingReminder?.dueDate else {
            return "In 5 minutes"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mock Notification Card

private struct MockNotificationCard: View {
    let title: String
    let time: String

    var body: some View {
        VStack(spacing: 0) {
            // Notification header
            HStack(spacing: Theme.Spacing.sm) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text("POWER REMINDERS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(time)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Notification body
            HStack {
                Text(title)
                    .font(Theme.Typography.headline)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.top, Theme.Spacing.xs)

            // Action buttons
            HStack(spacing: Theme.Spacing.sm) {
                MockActionButton(title: "Complete", icon: "checkmark.circle.fill", color: Theme.Colors.success)
                MockActionButton(title: "Snooze 5m", icon: "clock.arrow.circlepath", color: Color.accentColor)
                MockActionButton(title: "Snooze 15m", icon: "clock.arrow.circlepath", color: Color.accentColor)
            }
            .padding(.top, Theme.Spacing.md)
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

private struct MockActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
