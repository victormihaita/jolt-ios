import SwiftUI
import UIKit
import PRNetworking

struct DevicesListView: View {
    @StateObject private var viewModel = DevicesListViewModel()

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
                Section {
                    ForEach(viewModel.devices) { device in
                        DeviceRow(
                            device: device,
                            isCurrentDevice: device.id == viewModel.currentDeviceId
                        )
                    }
                } header: {
                    Text("\(viewModel.devices.count) Device\(viewModel.devices.count == 1 ? "" : "s")")
                } footer: {
                    Text("Devices are automatically registered when you sign in.")
                }
            }
        }
        .navigationTitle("Devices")
        .refreshable {
            await viewModel.fetchDevices()
        }
        .task {
            await viewModel.fetchDevices()
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

    var currentDeviceId: String? {
        let currentDeviceName = UIDevice.current.name
        return devices.first { $0.deviceName == currentDeviceName }?.id
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
}

#Preview {
    NavigationStack {
        DevicesListView()
    }
}
