import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPremiumSheet = false
    @State private var showSoundPicker = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    HStack(spacing: Theme.Spacing.md) {
                        // Avatar
                        if let avatarUrl = authViewModel.currentUser?.avatarUrl,
                           let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 56, height: 56)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.secondary)
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            // Display name
                            Text(authViewModel.currentUser?.displayName ?? "Not signed in")
                                .font(Theme.Typography.headline)

                            // Email
                            if let email = authViewModel.userEmail {
                                Text(email)
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Premium status
                            Text(subscriptionViewModel.isPremium ? "Premium" : "Free Plan")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(subscriptionViewModel.isPremium ? Color.purple : .secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                } header: {
                    Text("Account")
                }

                // Premium Section
                if !subscriptionViewModel.isPremium {
                    Section {
                        Button(action: { showPremiumSheet = true }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)

                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text("Upgrade to Premium")
                                        .font(Theme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("Custom snooze, unlimited devices & more")
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Preferences Section
                Section {
                    Button(action: { showSoundPicker = true }) {
                        HStack {
                            Label("Notification Sound", systemImage: "bell.badge")
                            Spacer()
                            Text("Gentle Chime")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }

                    HStack {
                        Label("Time Zone", systemImage: "globe")
                        Spacer()
                        Text("Auto")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Preferences")
                }

                // Sync Section
                Section {
                    HStack {
                        Label("Sync Status", systemImage: "icloud")
                        Spacer()
                        HStack(spacing: Theme.Spacing.xs) {
                            Text("Up to date")
                                .foregroundStyle(.secondary)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    HStack {
                        Label("Devices", systemImage: "iphone")
                        Spacer()
                        Text("1 device")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Sync")
                }

                // About Section
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Jolt", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://jolt.app/help")!) {
                        HStack {
                            Label("Help & Support", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://jolt.app/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive, action: { showSignOutConfirmation = true }) {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumView()
            }
            .sheet(isPresented: $showSoundPicker) {
                NotificationSoundPickerView()
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @AppStorage("appearance") private var appearance = 0 // 0: System, 1: Light, 2: Dark

    var body: some View {
        List {
            Section {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text("Choose how Jolt appears on your device.")
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Text("Jolt")
                        .font(Theme.Typography.title)

                    Text("Version 1.0.0")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            }

            Section {
                Text("Jolt helps you remember what matters with custom snoozing, powerful recurring reminders, and seamless cross-device sync.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
    }
}

// MARK: - Notification Sound Picker

struct NotificationSoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @State private var selectedSound = "gentle_chime"

    let freeSounds = [
        ("gentle_chime", "Gentle Chime"),
        ("bell_ding", "Bell Ding"),
        ("soft_alert", "Soft Alert")
    ]

    let premiumSounds = [
        ("crystal", "Crystal"),
        ("zen_bowl", "Zen Bowl"),
        ("nature_bird", "Nature Bird"),
        ("piano_note", "Piano Note")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(freeSounds, id: \.0) { sound in
                        SoundRow(
                            id: sound.0,
                            name: sound.1,
                            isSelected: selectedSound == sound.0,
                            isLocked: false
                        ) {
                            selectedSound = sound.0
                            playSound(sound.0)
                        }
                    }
                } header: {
                    Text("Free Sounds")
                }

                Section {
                    ForEach(premiumSounds, id: \.0) { sound in
                        SoundRow(
                            id: sound.0,
                            name: sound.1,
                            isSelected: selectedSound == sound.0,
                            isLocked: !subscriptionViewModel.isPremium
                        ) {
                            if subscriptionViewModel.isPremium {
                                selectedSound = sound.0
                                playSound(sound.0)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Premium Sounds")
                        if !subscriptionViewModel.isPremium {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                        }
                    }
                }
            }
            .navigationTitle("Notification Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func playSound(_ soundId: String) {
        // TODO: Play sound preview
        Haptics.light()
    }
}

struct SoundRow: View {
    let id: String
    let name: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .foregroundColor(isLocked ? .secondary : .primary)

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }

                Button(action: {
                    // Play preview
                    Haptics.light()
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isLocked)
    }
}

// MARK: - Premium View

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @State private var selectedPlan = 1 // 0: Monthly, 1: Yearly, 2: Lifetime

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.Colors.premiumGradient)

                        Text("Unlock the Full Experience")
                            .font(Theme.Typography.title2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Features
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SettingsPremiumFeatureRow(
                            icon: "clock.arrow.circlepath",
                            title: "Custom snooze times",
                            description: "Snooze for exactly 22 minutes"
                        )

                        SettingsPremiumFeatureRow(
                            icon: "repeat",
                            title: "Advanced recurring reminders",
                            description: "Every 2nd Tuesday, custom days"
                        )

                        SettingsPremiumFeatureRow(
                            icon: "icloud",
                            title: "Unlimited device sync",
                            description: "All your devices, always in sync"
                        )

                        SettingsPremiumFeatureRow(
                            icon: "speaker.wave.2",
                            title: "Premium notification sounds",
                            description: "Crystal, Zen Bowl, and more"
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Divider()
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Plans
                    VStack(spacing: Theme.Spacing.md) {
                        PlanButton(
                            title: "$19.99/year",
                            subtitle: "Save 44%",
                            badge: "BEST VALUE",
                            isSelected: selectedPlan == 1
                        ) {
                            selectedPlan = 1
                        }

                        PlanButton(
                            title: "$2.99/month",
                            subtitle: nil,
                            badge: nil,
                            isSelected: selectedPlan == 0
                        ) {
                            selectedPlan = 0
                        }

                        PlanButton(
                            title: "$49.99 lifetime",
                            subtitle: "Pay once, use forever",
                            badge: nil,
                            isSelected: selectedPlan == 2
                        ) {
                            selectedPlan = 2
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Subscribe Button
                    Button(action: subscribe) {
                        Text("Continue")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Restore Purchases
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: Theme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func subscribe() {
        Haptics.medium()
        // TODO: Implement RevenueCat subscription
    }

    private func restorePurchases() {
        Haptics.light()
        // TODO: Implement restore purchases
    }
}

private struct SettingsPremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Theme.Typography.headline)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PlanButton: View {
    let title: String
    let subtitle: String?
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack {
                        Text(title)
                            .font(Theme.Typography.headline)

                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(SubscriptionViewModel())
}
