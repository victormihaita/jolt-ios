import SwiftUI
import UIKit
import PRNetworking

struct DevicesListView: View {
    @StateObject private var viewModel = DevicesListViewModel()
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.devices.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if viewModel.devices.isEmpty {
                Section {
                    Text("No devices registered")
                        .foregroundStyle(.secondary)
                }
            } else {
                // Device limit warning for free users
                if viewModel.isAtDeviceLimit {
                    Section {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Device Limit Reached")
                                    .font(Theme.Typography.headline)
                            }

                            Text("Free accounts are limited to \(DevicesListViewModel.freeDeviceLimit) devices. Upgrade to Premium for unlimited devices.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                viewModel.showUpgradePrompt = true
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Upgrade to Premium")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                            .padding(.top, Theme.Spacing.xs)
                        }
                    }
                }

                Section {
                    ForEach(viewModel.devices) { device in
                        let isCurrentDevice = device.id == viewModel.currentDeviceId

                        DeviceRow(
                            device: device,
                            isCurrentDevice: isCurrentDevice
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !isCurrentDevice {
                                Button(role: .destructive) {
                                    viewModel.confirmDelete(device)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("\(viewModel.devices.count) Device\(viewModel.devices.count == 1 ? "" : "s")")
                        if !viewModel.isPremium {
                            Text("(\(DevicesListViewModel.freeDeviceLimit) max)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Swipe left on a device to remove it. You cannot remove the current device.")
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(Theme.Typography.caption)
                }
            }
        }
        .navigationTitle("Devices")
        .refreshable {
            await viewModel.fetchDevices()
        }
        .task {
            viewModel.isPremium = subscriptionViewModel.isPremium
            await viewModel.fetchDevices()
        }
        .confirmationDialog(
            "Remove Device?",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.deleteDevice()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let device = viewModel.deviceToDelete {
                Text("Remove \"\(device.displayName)\"? This device will no longer receive push notifications.")
            }
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            PaywallView()
        }
        .overlay {
            if viewModel.isDeleting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: Theme.Spacing.md) {
                        ProgressView()
                        Text("Removing...")
                            .font(Theme.Typography.subheadline)
                    }
                    .padding(Theme.Spacing.lg)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
    }
}

struct DeviceRow: View {
    let device: SettingsDevice
    let isCurrentDevice: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: device.platformIcon)
                .font(.title2)
                .foregroundStyle(isCurrentDevice ? Color.accentColor : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack {
                    Text(device.displayName)
                        .font(Theme.Typography.headline)

                    if isCurrentDevice {
                        Text("This device")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: Theme.Spacing.sm) {
                    if let appVersion = device.appVersion {
                        Text("v\(appVersion)")
                    }
                    if let osVersion = device.osVersion {
                        Text(device.platform == .ios ? "iOS \(osVersion)" : "Android \(osVersion)")
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xxs)
    }
}

// MARK: - ViewModel

@MainActor
class DevicesListViewModel: ObservableObject {
    @Published var devices: [SettingsDevice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeleting = false
    @Published var deviceToDelete: SettingsDevice?
    @Published var showDeleteConfirmation = false
    @Published var showUpgradePrompt = false

    var isPremium = false
    static let freeDeviceLimit = 2

    var currentDeviceId: String? {
        // Match by device name (existing approach)
        let currentDeviceName = UIDevice.current.name
        return devices.first { $0.deviceName == currentDeviceName }?.id
    }

    var isAtDeviceLimit: Bool {
        !isPremium && devices.count >= Self.freeDeviceLimit
    }

    func fetchDevices() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let query = PRAPI.DevicesQuery()
            let result = try await GraphQLClient.shared.fetch(query: query)

            devices = result.devices.map { device in
                SettingsDevice(
                    id: device.id,
                    platform: device.platform.value ?? .ios,
                    deviceName: device.deviceName,
                    appVersion: device.appVersion,
                    osVersion: device.osVersion,
                    lastSeenAt: device.lastSeenAt,
                    createdAt: device.createdAt
                )
            }.sorted { d1, d2 in
                d1.lastSeenAt > d2.lastSeenAt
            }
        } catch {
            errorMessage = "Failed to fetch devices: \(error.localizedDescription)"
        }
    }

    func confirmDelete(_ device: SettingsDevice) {
        deviceToDelete = device
        showDeleteConfirmation = true
    }

    func deleteDevice() async {
        guard let device = deviceToDelete else { return }

        isDeleting = true
        defer {
            isDeleting = false
            deviceToDelete = nil
        }

        do {
            try await DeviceService.shared.unregisterOtherDevice(id: device.id)

            // Remove from local list
            devices.removeAll { $0.id == device.id }

            Haptics.success()
        } catch {
            errorMessage = "Failed to remove device: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}

#Preview {
    NavigationStack {
        DevicesListView()
            .environmentObject(SubscriptionViewModel())
    }
}
