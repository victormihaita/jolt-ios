import Foundation
import Network
import Combine

/// Monitors network connectivity using NWPathMonitor (modern iOS API)
public final class NetworkReachability: ObservableObject {
    public static let shared = NetworkReachability()

    /// Whether the device currently has network connectivity
    @Published public private(set) var isConnected: Bool = true

    /// The type of network connection
    @Published public private(set) var connectionType: ConnectionType = .unknown

    /// Network connection types
    public enum ConnectionType: String {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.pr.networkmonitor", qos: .utility)

    /// Notification posted when network becomes available
    public static let didBecomeAvailable = Notification.Name("NetworkReachability.didBecomeAvailable")

    /// Notification posted when network becomes unavailable
    public static let didBecomeUnavailable = Notification.Name("NetworkReachability.didBecomeUnavailable")

    private init() {
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let connected = path.status == .satisfied
            let type = self.determineConnectionType(path)

            DispatchQueue.main.async {
                let wasConnected = self.isConnected
                self.isConnected = connected
                self.connectionType = type

                // Post notifications on state change
                if connected && !wasConnected {
                    print("📶 Network: Connected (\(type.rawValue))")
                    NotificationCenter.default.post(name: Self.didBecomeAvailable, object: nil)
                } else if !connected && wasConnected {
                    print("📶 Network: Disconnected")
                    NotificationCenter.default.post(name: Self.didBecomeUnavailable, object: nil)
                }
            }
        }

        monitor.start(queue: queue)
    }

    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        }
        return .unknown
    }

    // MARK: - Convenience

    /// Check if network is available synchronously
    public var isAvailable: Bool {
        isConnected
    }

    /// Whether the connection is expensive (cellular)
    public var isExpensive: Bool {
        connectionType == .cellular
    }
}
