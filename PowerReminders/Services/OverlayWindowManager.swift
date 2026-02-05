import UIKit
import SwiftUI
import Combine

/// Manages a dedicated UIWindow that renders the notification banner above all app content,
/// including sheets, fullScreenCovers, and navigation stacks.
@MainActor
final class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private var overlayWindow: PassthroughWindow?
    private var containerVC: PassthroughViewController?
    private var hostingController: UIHostingController<OverlayRootView>?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// Call once during app launch (e.g. in AppDelegate) to start observing notification state.
    func setup() {
        InAppNotificationManager.shared.$isVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVisible in
                if isVisible {
                    self?.showWindow()
                } else {
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)
    }

    private func showWindow() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        if overlayWindow == nil {
            let window = PassthroughWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = true

            // Container VC with passthrough view as root
            let container = PassthroughViewController()

            // Hosting controller sized to its SwiftUI content (no full-screen expansion)
            let rootView = OverlayRootView()
            let hosting = UIHostingController(rootView: rootView)
            hosting.view.backgroundColor = .clear
            hosting.view.isOpaque = false
            hosting.sizingOptions = .intrinsicContentSize

            // Add hosting as child of container
            container.addChild(hosting)
            container.view.addSubview(hosting.view)
            hosting.didMove(toParent: container)

            // Pin hosting view to top/leading/trailing only — no bottom constraint
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.topAnchor.constraint(equalTo: container.view.topAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            ])

            window.rootViewController = container
            self.containerVC = container
            self.hostingController = hosting
            self.overlayWindow = window
        }

        overlayWindow?.isHidden = false
        overlayWindow?.makeKeyAndVisible()

        // Return key window status to the main app window
        DispatchQueue.main.async {
            if let mainWindow = scene.windows.first(where: { !($0 is PassthroughWindow) }) {
                mainWindow.makeKey()
            }
        }
    }

    private func hideWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            if !InAppNotificationManager.shared.isVisible {
                self.overlayWindow?.isHidden = true
            }
        }
    }
}

// MARK: - Passthrough Window

/// A UIWindow subclass that passes through touches in areas where there's no content.
private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        // If the hit landed on our passthrough container view, pass through to the app
        if hitView is PassthroughView {
            return nil
        }
        return hitView
    }
}

// MARK: - Passthrough View & Controller

/// A UIView that passes through touches that land on itself (not on subviews).
private class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}

/// Container view controller that uses PassthroughView so areas outside the banner pass through.
private class PassthroughViewController: UIViewController {
    override func loadView() {
        view = PassthroughView()
    }
}

// MARK: - Overlay Root View

/// The SwiftUI view hosted inside the overlay window.
/// Renders ONLY the banner — no Spacer or full-screen expansion.
private struct OverlayRootView: View {
    @ObservedObject private var notificationManager = InAppNotificationManager.shared
    @ObservedObject private var revenueCatService = RevenueCatService.shared

    @State private var showPaywall = false

    var body: some View {
        if notificationManager.isVisible, let notification = notificationManager.currentNotification {
            InAppNotificationBanner(
                title: notification.title,
                subtitle: notification.subtitle,
                reminderID: notification.reminderID,
                dueAt: notification.dueAt,
                soundID: notification.soundID,
                isAlarm: notification.isAlarm,
                isPremium: revenueCatService.isPremium,
                onComplete: {
                    notificationManager.handleComplete()
                },
                onSnooze: { minutes in
                    notificationManager.handleSnooze(minutes: minutes)
                },
                onDismiss: {
                    notificationManager.dismiss()
                },
                onTap: {
                    notificationManager.dismiss()
                },
                onShowPaywall: {
                    showPaywall = true
                },
                initialSnoozeExpanded: notificationManager.snoozeExpanded
            )
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, 60)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).animation(.easeOut(duration: 0.3)),
                removal: .move(edge: .top).combined(with: .opacity).animation(.easeIn(duration: 0.2))
            ))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}
