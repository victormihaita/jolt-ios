import Foundation
import UIKit
import PRNetworking
import ApolloAPI

/// Service for managing device registration and push tokens
actor DeviceService {
    static let shared = DeviceService()

    private var currentDeviceID: UUID?
    private var currentPushToken: String?

    // Persist device ID across app launches
    private let deviceIDKey = "registeredDeviceID"

    private init() {
        // Restore device ID from UserDefaults on init
        if let idString = UserDefaults.standard.string(forKey: deviceIDKey),
           let id = UUID(uuidString: idString) {
            currentDeviceID = id
        }
    }

    /// Public getter for the current device's registered ID
    var deviceID: UUID? {
        currentDeviceID
    }

    // MARK: - Push Token Registration

    func registerPushToken(_ token: String) async {
        currentPushToken = token

        // Only register if user is authenticated
        guard KeychainService.shared.getToken() != nil else {
            return
        }

        await registerDevice()
    }

    // MARK: - Device Registration

    func registerDevice() async {
        guard let pushToken = currentPushToken else {
            return
        }

        let deviceName = await UIDevice.current.name
        let osVersion = await UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        let input = PRAPI.RegisterDeviceInput(
            platform: .case(.ios),
            pushToken: pushToken,
            deviceName: deviceName.isEmpty ? .null : .some(deviceName),
            appVersion: appVersion.map { .some($0) } ?? .null,
            osVersion: osVersion.isEmpty ? .null : .some(osVersion)
        )

        let mutation = PRAPI.RegisterDeviceMutation(input: input)

        do {
            let result = try await GraphQLClient.shared.perform(mutation: mutation)
            if let id = UUID(uuidString: result.registerDevice.id) {
                currentDeviceID = id
                // Persist device ID to UserDefaults
                UserDefaults.standard.set(id.uuidString, forKey: deviceIDKey)
                print("Device registered: \(id)")
            }
        } catch {
            print("Failed to register device: \(error)")
        }
    }

    /// Unregister a different device (not the current device)
    /// Used for device management in Settings
    func unregisterOtherDevice(id: String) async throws {
        let mutation = PRAPI.UnregisterDeviceMutation(id: id)
        _ = try await GraphQLClient.shared.perform(mutation: mutation)
        print("Device unregistered: \(id)")
    }

    func unregisterDevice() async {
        guard let deviceID = currentDeviceID else { return }

        let mutation = PRAPI.UnregisterDeviceMutation(id: deviceID.uuidString)

        do {
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            currentDeviceID = nil
            print("Device unregistered")
        } catch {
            print("Failed to unregister device: \(error)")
        }
    }

    // MARK: - Authentication Events

    func onUserAuthenticated() async {
        await registerDevice()
    }

    func onUserLogout() async {
        await unregisterDevice()
        currentPushToken = nil
        // Clear persisted device ID
        UserDefaults.standard.removeObject(forKey: deviceIDKey)
    }
}
