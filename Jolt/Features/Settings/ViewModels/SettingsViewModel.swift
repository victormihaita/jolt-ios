import Foundation
import SwiftUI
import Combine
import JoltSync
import JoltNetworking

@MainActor
class SettingsViewModel: ObservableObject {
    // Sync status properties
    @Published var isSyncing: Bool = false
    @Published var lastSyncAt: Date?
    @Published var syncError: Error?

    // Devices
    @Published var devices: [SettingsDevice] = []
    @Published var isLoadingDevices: Bool = false
    @Published var hasFetchedDevices: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeSyncEngine()
    }

    private func observeSyncEngine() {
        SyncEngine.shared.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        SyncEngine.shared.$lastSyncAt
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSyncAt)

        SyncEngine.shared.$syncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncError)
    }

    // MARK: - Sync Status Display

    var syncStatusText: String {
        if isSyncing {
            return "Syncing..."
        }
        if syncError != nil {
            return "Sync error"
        }
        guard let lastSync = lastSyncAt else {
            return "Not synced"
        }
        return relativeSyncTime(from: lastSync)
    }

    var syncStatusIcon: String {
        if isSyncing {
            return "arrow.triangle.2.circlepath"
        }
        if syncError != nil {
            return "exclamationmark.circle.fill"
        }
        return "checkmark.circle.fill"
    }

    var syncStatusColor: Color {
        if isSyncing {
            return .blue
        }
        if syncError != nil {
            return .red
        }
        return .green
    }

    private func relativeSyncTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Up to date"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days > 1 ? "s" : "") ago"
        }
    }

    // MARK: - Manual Sync

    func triggerSync() {
        Haptics.light()
        SyncEngine.shared.refetch()
    }

    // MARK: - Devices

    func fetchDevices() async {
        isLoadingDevices = true
        defer {
            isLoadingDevices = false
            hasFetchedDevices = true
        }

        do {
            let query = JoltAPI.DevicesQuery()
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
            print("Failed to fetch devices: \(error)")
        }
    }

    var deviceCount: Int {
        // If we haven't fetched yet, show 1 (current device) as a reasonable default
        if !hasFetchedDevices {
            return 1
        }
        // After fetching, show actual count (minimum 1 for current device)
        return max(1, devices.count)
    }

    var devicesDisplayText: String {
        let count = deviceCount
        return count == 1 ? "1 device" : "\(count) devices"
    }
}

// MARK: - Device Model for Settings

struct SettingsDevice: Identifiable {
    let id: String
    let platform: JoltAPI.Platform
    let deviceName: String?
    let appVersion: String?
    let osVersion: String?
    let lastSeenAt: String
    let createdAt: String

    var displayName: String {
        deviceName ?? "Unknown Device"
    }

    var platformIcon: String {
        switch platform {
        case .ios: return "iphone"
        case .android: return "candybarphone"
        }
    }
}
