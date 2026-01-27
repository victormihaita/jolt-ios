import SwiftUI
import PRModels
import PRNetworking

/// A standalone snooze picker view for use when triggered from push notifications.
/// This view handles the snooze mutation directly without needing a view model.
struct NotificationSnoozePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel

    let reminder: PRModels.Reminder

    @State private var customMinutes = 15
    @State private var showPremiumPrompt = false
    @State private var isLoading = false

    let quickOptions = [5, 15, 30, 60] // minutes

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Reminder title for context
                Text(reminder.title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                Text("Remind me again in...")
                    .font(Theme.Typography.headline)

                // Quick Options
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(quickOptions, id: \.self) { minutes in
                        QuickSnoozeButton(minutes: minutes, isLoading: isLoading) {
                            snooze(minutes: minutes)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Divider()
                    .padding(.vertical, Theme.Spacing.md)

                // Custom Snooze (Premium)
                if subscriptionViewModel.isPremium {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack {
                            Text("Custom time:")
                                .font(Theme.Typography.body)

                            Spacer()

                            Picker("Minutes", selection: $customMinutes) {
                                ForEach(1...120, id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        Button(action: { snooze(minutes: customMinutes) }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Snooze for \(customMinutes) minutes")
                            }
                            .font(Theme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                } else {
                    // Premium Upsell
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)

                        Text("Unlock Custom Snooze")
                            .font(Theme.Typography.headline)

                        Text("Snooze for any amount of time you choose")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: { showPremiumPrompt = true }) {
                            Text("Upgrade to Premium")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(Theme.Colors.premiumGradient)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .liquidGlass()
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()
            }
            .navigationTitle("Snooze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumPrompt) {
                PaywallView()
            }
        }
        .presentationDetents([.medium])
    }

    private func snooze(minutes: Int) {
        Haptics.medium()
        isLoading = true

        Task {
            let mutation = PRAPI.SnoozeReminderMutation(id: reminder.id.uuidString, minutes: minutes)

            do {
                _ = try await GraphQLClient.shared.perform(mutation: mutation)
                print("Snoozed reminder \(reminder.id) for \(minutes) minutes from notification picker")

                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .reminderSnoozed,
                        object: nil,
                        userInfo: ["reminder_id": reminder.id, "minutes": minutes]
                    )
                }

                Haptics.success()

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Failed to snooze reminder from notification picker: \(error)")
                Haptics.error()

                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Quick Snooze Button

private struct QuickSnoozeButton: View {
    let minutes: Int
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(displayValue)
                    .font(Theme.Typography.title2)
                    .fontWeight(.semibold)
                Text(displayUnit)
                    .font(Theme.Typography.caption)
            }
            .frame(width: 60, height: 60)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.5 : 1)
    }

    private var displayValue: String {
        if minutes >= 60 {
            return "\(minutes / 60)"
        }
        return "\(minutes)"
    }

    private var displayUnit: String {
        if minutes >= 60 {
            let hours = minutes / 60
            return hours == 1 ? "hour" : "hours"
        }
        return "min"
    }
}
