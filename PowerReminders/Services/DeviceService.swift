import Foundation
import UIKit
import PRNetworking
import PRKeychain
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
            print("📱 DeviceService.init(): Restored device ID from UserDefaults: \(id)")
        } else {
            print("📱 DeviceService.init(): No device ID found in UserDefaults")
        }
    }

    /// Public getter for the current device's registered ID
    var deviceID: UUID? {
        currentDeviceID
    }

    // MARK: - Push Token Registration

    func registerPushToken(_ token: String) async {
        print("📱 DeviceService.registerPushToken() called with token: \(token.prefix(20))...")
        currentPushToken = token

        // Only register if user is authenticated
        guard PRKeychain.KeychainService.shared.getToken() != nil else {
            print("📱 DeviceService: No auth token, will register when user authenticates")
            return
        }

        print("📱 DeviceService: User is authenticated, proceeding with registration")
        await registerDevice()
    }

    // MARK: - Device Registration

    func registerDevice() async {
        print("📱 DeviceService.registerDevice() called")
        print("📱 DeviceService: currentPushToken = \(currentPushToken ?? "nil")")

        guard let pushToken = currentPushToken, !pushToken.isEmpty else {
            print("📱 DeviceService: No push token available, skipping registration")
            return
        }

        // Verify we have an auth token
        guard PRKeychain.KeychainService.shared.getToken() != nil else {
            print("📱 DeviceService: No auth token in registerDevice(), skipping")
            return
        }


        let deviceName = await UIDevice.current.name
        let osVersion = await UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        print("📱 DeviceService: Registering device '\(deviceName)' with token \(pushToken.prefix(20))...")

        let input = PRAPI.RegisterDeviceInput(
            platform: .case(.ios),
            pushToken: pushToken,
            deviceName: deviceName.isEmpty ? .null : .some(deviceName),
            appVersion: appVersion.map { .some($0) } ?? .null,
            osVersion: osVersion.isEmpty ? .null : .some(osVersion)
        )

        let mutation = PRAPI.RegisterDeviceMutation(input: input)

        do {
            print("📱 DeviceService: Calling GraphQL mutation...")
            let result = try await GraphQLClient.shared.perform(mutation: mutation)
            if let id = UUID(uuidString: result.registerDevice.id) {
                currentDeviceID = id
                // Persist device ID to UserDefaults
                UserDefaults.standard.set(id.uuidString, forKey: deviceIDKey)
                print("📱 DeviceService: ✅ Device registered successfully: \(id)")
            }
        } catch {
            print("📱 DeviceService: ❌ Failed to register device: \(error)")
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
        guard let deviceID = currentDeviceID else {
            print("📱 DeviceService.unregisterDevice(): No device ID to unregister")
            return
        }

        print("📱 DeviceService.unregisterDevice(): Unregistering device \(deviceID)...")
        let mutation = PRAPI.UnregisterDeviceMutation(id: deviceID.uuidString)

        do {
            _ = try await GraphQLClient.shared.perform(mutation: mutation)
            currentDeviceID = nil
            print("📱 DeviceService: ✅ Device unregistered successfully")
        } catch {
            print("📱 DeviceService: ❌ Failed to unregister device: \(error)")
        }
    }

    // MARK: - Authentication Events

    func onUserAuthenticated() async {
        print("📱 DeviceService.onUserAuthenticated() called")
        print("📱 DeviceService: currentPushToken at auth = \(currentPushToken ?? "nil")")
        await registerDevice()
    }

    func onUserLogout() async {
        print("📱 DeviceService.onUserLogout() called")
        await unregisterDevice()
        currentPushToken = nil
        // Clear persisted device ID
        UserDefaults.standard.removeObject(forKey: deviceIDKey)
        print("📱 DeviceService: Logout cleanup complete")
    }
}
