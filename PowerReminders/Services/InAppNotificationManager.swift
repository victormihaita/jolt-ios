import SwiftUI
import AVFoundation
import PRNetworking
import PRSync

@MainActor
class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()

    @Published var currentNotification: InAppNotificationData?
    @Published var isVisible = false

    private var audioPlayer: AVAudioPlayer?
    private var dismissTask: Task<Void, Never>?
    private let autoDismissDelay: TimeInterval = 10.0

    struct InAppNotificationData: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let subtitle: String
        let reminderID: UUID
        let dueAt: Date?
        let soundID: String?
        let isAlarm: Bool

        static func == (lhs: InAppNotificationData, rhs: InAppNotificationData) -> Bool {
            lhs.id == rhs.id
        }
    }

    private init() {}

    func show(
        title: String,
        subtitle: String,
        reminderID: UUID,
        dueAt: Date?,
        soundID: String?,
        isAlarm: Bool
    ) {
        // Cancel any pending dismiss
        dismissTask?.cancel()

        // Create notification data
        let notification = InAppNotificationData(
            title: title,
            subtitle: subtitle,
            reminderID: reminderID,
            dueAt: dueAt,
            soundID: soundID,
            isAlarm: isAlarm
        )

        // Play sound (not for alarms - AlarmManager handles those)
        if let soundID = soundID, !isAlarm {
            playSoundFromBundle(soundID)
        }

        // Trigger haptic
        Haptics.medium()

        // Show with animation
        withAnimation(.bouncy) {
            currentNotification = notification
            isVisible = true
        }

        // Schedule auto-dismiss (not for alarms)
        if !isAlarm {
            scheduleAutoDismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()

        withAnimation(.snappy) {
            isVisible = false
        }

        // Clear after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentNotification = nil
        }
    }

    func handleComplete() {
        guard let notification = currentNotification else { return }

        Haptics.success()

        Task {
            let mutation = PRAPI.CompleteReminderMutation(id: notification.reminderID.uuidString)

            do {
                _ = try await GraphQLClient.shared.perform(mutation: mutation)
                SyncEngine.shared.refetch()

                NotificationCenter.default.post(
                    name: .reminderCompleted,
                    object: nil,
                    userInfo: ["reminder_id": notification.reminderID]
                )
            } catch {
                print("InAppNotificationManager: Failed to complete reminder: \(error)")
                Haptics.error()
            }
        }

        dismiss()
    }

    func handleSnooze(minutes: Int) {
        guard let notification = currentNotification else { return }

        Haptics.medium()

        Task {
            let mutation = PRAPI.SnoozeReminderMutation(
                id: notification.reminderID.uuidString,
                minutes: minutes
            )

            do {
                _ = try await GraphQLClient.shared.perform(mutation: mutation)
                SyncEngine.shared.refetch()

                NotificationCenter.default.post(
                    name: .reminderSnoozed,
                    object: nil,
                    userInfo: ["reminder_id": notification.reminderID, "minutes": minutes]
                )
                Haptics.success()
            } catch {
                print("InAppNotificationManager: Failed to snooze reminder: \(error)")
                Haptics.error()
            }
        }

        dismiss()
    }

    private func scheduleAutoDismiss() {
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((self?.autoDismissDelay ?? 10.0) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.dismiss()
            }
        }
    }

    private func playSoundFromBundle(_ filename: String) {
        let baseName = (filename as NSString).deletingPathExtension

        if let url = Bundle.main.url(forResource: baseName, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                print("InAppNotificationManager: Playing custom sound '\(filename)'")
            } catch {
                print("InAppNotificationManager: Failed to play sound \(filename): \(error)")
                Haptics.medium()
            }
        } else {
            print("InAppNotificationManager: Sound file not found: \(filename)")
            Haptics.medium()
        }
    }
}
