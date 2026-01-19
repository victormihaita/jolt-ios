import Foundation
import UIKit
import JoltNetworking
import ApolloAPI

/// Service for managing device registration and push tokens
actor DeviceService {
    static let shared = DeviceService()

    private var currentDeviceID: UUID?
    private var currentPushToken: String?

    private init() {}

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

        let input = JoltAPI.RegisterDeviceInput(
            platform: .case(.ios),
            pushToken: pushToken,
            deviceName: deviceName.isEmpty ? .null : .some(deviceName),
            appVersion: appVersion.map { .some($0) } ?? .null,
            osVersion: osVersion.isEmpty ? .null : .some(osVersion)
        )

        let mutation = JoltAPI.RegisterDeviceMutation(input: input)

        do {
            let result = try await GraphQLClient.shared.perform(mutation: mutation)
            if let id = UUID(uuidString: result.registerDevice.id) {
                currentDeviceID = id
                print("Device registered: \(id)")
            }
        } catch {
            print("Failed to register device: \(error)")
        }
    }

    func unregisterDevice() async {
        guard let deviceID = currentDeviceID else { return }

        let mutation = JoltAPI.UnregisterDeviceMutation(id: deviceID.uuidString)

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
    }
}
