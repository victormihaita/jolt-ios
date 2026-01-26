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

                    SettingsRow(
                        icon: "globe",
                        iconColor: .blue,
                        title: "Time Zone",
                        value: timezoneDisplayText
                    )
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

                    Link(destination: URL(string: "https://powerreminders.app/help")!) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            iconColor: .green,
                            title: "Help & Support",
                            isExternalLink: true
                        )
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://powerreminders.app/privacy")!) {
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
                PremiumView()
            }
            .sheet(isPresented: $showSoundPicker) {
                NotificationSoundPickerView()
            }
            .task {
                await settingsViewModel.fetchDevices()
            }
        }
    }

    // MARK: - Computed Properties

    private var timezoneDisplayText: String {
        guard let userTimezone = authViewModel.currentUser?.timezone else {
            return "Auto"
        }
        if userTimezone == TimeZone.current.identifier {
            return "Auto"
        }
        if let tz = TimeZone(identifier: userTimezone) {
            return tz.abbreviation() ?? userTimezone
        }
        return userTimezone
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

// MARK: - Premium View

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @State private var selectedPlan = 1 // 0: Monthly, 1: Yearly, 2: Lifetime
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

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

                    // Plans - Use actual prices from RevenueCat when available
                    VStack(spacing: Theme.Spacing.md) {
                        if let annual = revenueCat.annualPackage {
                            PlanButton(
                                title: "\(annual.priceString)/year",
                                subtitle: annual.savingsPercentage.map { "Save \($0)%" },
                                badge: "BEST VALUE",
                                isSelected: selectedPlan == 1
                            ) {
                                selectedPlan = 1
                            }
                        } else {
                            PlanButton(
                                title: "$19.99/year",
                                subtitle: "Save 44%",
                                badge: "BEST VALUE",
                                isSelected: selectedPlan == 1
                            ) {
                                selectedPlan = 1
                            }
                        }

                        if let monthly = revenueCat.monthlyPackage {
                            PlanButton(
                                title: "\(monthly.priceString)/month",
                                subtitle: nil,
                                badge: nil,
                                isSelected: selectedPlan == 0
                            ) {
                                selectedPlan = 0
                            }
                        } else {
                            PlanButton(
                                title: "$2.99/month",
                                subtitle: nil,
                                badge: nil,
                                isSelected: selectedPlan == 0
                            ) {
                                selectedPlan = 0
                            }
                        }

                        if let lifetime = revenueCat.lifetimePackage {
                            PlanButton(
                                title: "\(lifetime.priceString) lifetime",
                                subtitle: "Pay once, use forever",
                                badge: nil,
                                isSelected: selectedPlan == 2
                            ) {
                                selectedPlan = 2
                            }
                        } else {
                            PlanButton(
                                title: "$49.99 lifetime",
                                subtitle: "Pay once, use forever",
                                badge: nil,
                                isSelected: selectedPlan == 2
                            ) {
                                selectedPlan = 2
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Subscribe Button with loading state
                    Button(action: subscribe) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                            }
                        }
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(isLoading ? Color.gray : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    }
                    .disabled(isLoading || selectedPackage == nil)
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Restore Purchases
                    Button(action: restorePurchases) {
                        if revenueCat.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Restore Purchases")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(revenueCat.isLoading || isLoading)

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
            .task {
                await revenueCat.fetchOfferings()
            }
            .alert("Welcome to Premium!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for upgrading. Enjoy all premium features!")
            }
        }
    }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case 0: return revenueCat.monthlyPackage
        case 1: return revenueCat.annualPackage
        case 2: return revenueCat.lifetimePackage
        default: return nil
        }
    }

    private func subscribe() {
        guard let package = selectedPackage else { return }

        Haptics.medium()
        isLoading = true
        errorMessage = nil

        Task {
            let success = await revenueCat.purchase(package)
            isLoading = false

            if success {
                Haptics.success()
                showSuccessAlert = true
            } else if let error = revenueCat.errorMessage {
                errorMessage = error
                Haptics.error()
            }
        }
    }

    private func restorePurchases() {
        Haptics.light()
        errorMessage = nil

        Task {
            let restored = await revenueCat.restorePurchases()

            if restored {
                Haptics.success()
                showSuccessAlert = true
            } else if revenueCat.errorMessage == nil {
                errorMessage = "No previous purchases found"
            } else {
                errorMessage = revenueCat.errorMessage
                Haptics.error()
            }
        }
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
