import SwiftUI
import RevenueCat
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsViewModel = SettingsViewModel()
    @ObservedObject private var soundSettings = NotificationSoundSettings.shared
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
                        SettingsRow(
                            icon: "bell.badge",
                            iconColor: .red,
                            title: "Notification Sound",
                            value: soundSettings.selectedSoundDisplayName,
                            showChevron: true
                        )
                    }
                    .foregroundColor(.primary)

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "paintbrush",
                            iconColor: .purple,
                            title: "Appearance"
                        )
                    }
                } header: {
                    Text("Preferences")
                }

                // Notifications Section
                Section {
                    NotificationPermissionRow()
                } header: {
                    Text("Notifications")
                }

                // Sync Section
                Section {
                    Button(action: { settingsViewModel.triggerSync() }) {
                        HStack {
                            SettingsIconView(icon: "icloud", color: .blue)
                            Text("Sync Status")
                            Spacer()
                            HStack(spacing: Theme.Spacing.xs) {
                                if settingsViewModel.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text(settingsViewModel.syncStatusText)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: settingsViewModel.syncStatusIcon)
                                    .foregroundStyle(settingsViewModel.syncStatusColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    NavigationLink {
                        DevicesListView()
                    } label: {
                        HStack {
                            SettingsIconView(icon: "iphone", color: .gray)
                            Text("Devices")
                            Spacer()
                            if settingsViewModel.isLoadingDevices {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Text(settingsViewModel.devicesDisplayText)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Sync")
                }

                // About Section
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(
                            icon: "info.circle",
                            iconColor: .gray,
                            title: "About Power Reminders"
                        )
                    }

                    Link(destination: URL(string: "https://jolt-website-liart.vercel.app/help")!) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            iconColor: .green,
                            title: "Help & Support",
                            isExternalLink: true
                        )
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://jolt-website-liart.vercel.app/terms")!) {
                        SettingsRow(
                            icon: "doc.text",
                            iconColor: .orange,
                            title: "Terms of Service",
                            isExternalLink: true
                        )
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://jolt-website-liart.vercel.app/privacy")!) {
                        SettingsRow(
                            icon: "hand.raised",
                            iconColor: .blue,
                            title: "Privacy Policy",
                            isExternalLink: true
                        )
                    }
                    .foregroundColor(.primary)
                }

                // Sign Out Section
                Section {
                    Button(action: { showSignOutConfirmation = true }) {
                        HStack {
                            SettingsIconView(icon: "rectangle.portrait.and.arrow.right", color: .red)
                            Text("Sign Out")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                    .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
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
                PaywallView()
            }
            .sheet(isPresented: $showSoundPicker) {
                NotificationSoundPickerView()
            }
            .task {
                await settingsViewModel.fetchDevices()
            }
        }
    }

}

// MARK: - Settings Row Components

struct SettingsIconView: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.body)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    var isExternalLink: Bool = false

    var body: some View {
        HStack {
            SettingsIconView(icon: icon, color: iconColor)
            Text(title)
            Spacer()
            if let value {
                Text(value)
                    .foregroundStyle(.secondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if isExternalLink {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Notification Permission Row

struct NotificationPermissionRow: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var isChecking = true

    var body: some View {
        HStack {
            SettingsIconView(icon: statusIcon, color: statusColor)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Push Notifications")
                    .font(Theme.Typography.body)

                Text(statusDescription)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isChecking {
                ProgressView()
                    .scaleEffect(0.8)
            } else if status == .denied || status == .notDetermined {
                Button("Enable") {
                    openAppSettings()
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .task {
            await checkPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await checkPermissionStatus()
            }
        }
    }

    private var statusIcon: String {
        switch status {
        case .authorized, .provisional:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell"
        case .ephemeral:
            return "bell.badge"
        @unknown default:
            return "bell"
        }
    }

    private var statusColor: Color {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }

    private var statusDescription: String {
        switch status {
        case .authorized:
            return "You'll receive reminder notifications"
        case .provisional:
            return "Notifications delivered quietly"
        case .denied:
            return "Enable to receive reminder alerts"
        case .notDetermined:
            return "Enable to never miss a reminder"
        case .ephemeral:
            return "Temporary notifications enabled"
        @unknown default:
            return "Unknown status"
        }
    }

    private func checkPermissionStatus() async {
        isChecking = true
        status = await NotificationService.shared.getNotificationStatus()
        isChecking = false
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
                Text("Choose how Power Reminders appears on your device.")
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
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    Text("Power Reminders")
                        .font(Theme.Typography.title)

                    Text("Version 1.0.0")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            }

            Section {
                Text("Power Reminders helps you remember what matters with custom snoozing, powerful recurring reminders, and seamless cross-device sync.")
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
    @ObservedObject private var soundSettings = NotificationSoundSettings.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(soundSettings.freeSounds) { sound in
                        SoundRow(
                            id: sound.filename,
                            name: sound.name,
                            isSelected: soundSettings.selectedSound == sound.filename,
                            isLocked: false,
                            onSelect: {
                                // Select the sound (preview is handled separately)
                                _ = soundSettings.selectSound(sound.filename, isPremium: subscriptionViewModel.isPremium)
                            },
                            onPreview: {
                                soundSettings.playPreview(sound.filename)
                            }
                        )
                    }
                } header: {
                    Text("Free Sounds")
                }

                Section {
                    ForEach(soundSettings.premiumSounds) { sound in
                        SoundRow(
                            id: sound.filename,
                            name: sound.name,
                            isSelected: soundSettings.selectedSound == sound.filename,
                            isLocked: !subscriptionViewModel.isPremium,
                            onSelect: {
                                // Select the sound (preview is handled separately)
                                _ = soundSettings.selectSound(sound.filename, isPremium: subscriptionViewModel.isPremium)
                            },
                            onPreview: {
                                soundSettings.playPreview(sound.filename)
                            }
                        )
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
            .task {
                await soundSettings.fetchSounds()
            }
        }
    }
}

struct SoundRow: View {
    let id: String
    let name: String
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        if isLocked {
            // Premium sounds: separate preview button, no row selection
            HStack {
                HStack {
                    Text(name)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Preview button for locked sounds
                Button(action: onPreview) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
        } else {
            // Free sounds: tap anywhere to select AND play
            Button(action: {
                onSelect()
                onPreview()
            }) {
                HStack {
                    Text(name)
                        .foregroundColor(.primary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(SubscriptionViewModel())
}
