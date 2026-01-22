import AVFoundation
import UIKit
import AudioToolbox

/// Manages alarm sound playback and vibration for reminder notifications.
/// Supports playing alarm sounds that can be stopped from any device via cross-device sync.
/// Thread-safe: can be called from any thread.
class AlarmManager {
    static let shared = AlarmManager()

    private let lock = NSLock()
    private var audioPlayer: AVAudioPlayer?
    private var _isPlaying = false
    private var vibrationTimer: Timer?
    private var currentReminderID: UUID?
    private var systemSoundTask: Task<Void, Never>?

    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Alarm Control

    /// Starts playing the alarm sound and vibration for the specified reminder.
    /// Thread-safe: can be called from any thread.
    /// - Parameters:
    ///   - reminderID: The ID of the reminder triggering the alarm
    ///   - soundName: The name of the sound file to play (without extension)
    ///   - vibrate: Whether to also trigger vibration
    func startAlarm(
        for reminderID: UUID,
        soundName: String = "alarm_default",
        vibrate: Bool = true
    ) {
        lock.lock()
        // Don't start a new alarm if one is already playing
        guard !_isPlaying else {
            lock.unlock()
            return
        }

        currentReminderID = reminderID
        _isPlaying = true
        lock.unlock()

        // Try to play custom sound, fall back to system sound
        if !playCustomSound(named: soundName) {
            playSystemAlarmSound()
        }

        // Start vibration on main thread (Timer requires main thread)
        if vibrate {
            DispatchQueue.main.async { [weak self] in
                self?.startVibration()
            }
        }

        print("Started alarm for reminder: \(reminderID)")
    }

    /// Stops the currently playing alarm.
    /// Thread-safe: can be called from any thread.
    func stopAlarm() {
        lock.lock()
        guard _isPlaying else {
            lock.unlock()
            return
        }

        // Stop audio
        audioPlayer?.stop()
        audioPlayer = nil

        // Stop system sound task
        systemSoundTask?.cancel()
        systemSoundTask = nil

        _isPlaying = false

        let reminderID = currentReminderID
        currentReminderID = nil
        lock.unlock()

        // Invalidate timer on main thread (Timer is not thread-safe)
        DispatchQueue.main.async { [weak self] in
            self?.vibrationTimer?.invalidate()
            self?.vibrationTimer = nil
        }

        if let reminderID = reminderID {
            print("Stopped alarm for reminder: \(reminderID)")
        }
    }

    /// Returns the ID of the reminder for which the alarm is currently playing.
    var currentAlarmReminderID: UUID? {
        lock.lock()
        defer { lock.unlock() }
        return _isPlaying ? currentReminderID : nil
    }

    /// Returns whether an alarm is currently playing.
    var isAlarmPlaying: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isPlaying
    }

    // MARK: - Sound Playback

    private func playCustomSound(named soundName: String) -> Bool {
        // Try different extensions
        let extensions = ["m4a", "mp3", "wav", "caf"]

        for ext in extensions {
            if let url = Bundle.main.url(forResource: soundName, withExtension: ext) {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                    audioPlayer?.volume = 1.0
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    return true
                } catch {
                    print("Failed to play sound \(soundName).\(ext): \(error)")
                }
            }
        }

        return false
    }

    private func playSystemAlarmSound() {
        // Play system alarm sound on loop using a Task
        systemSoundTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isAlarmPlaying else { break }

                AudioServicesPlaySystemSound(1005) // Default alarm sound
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            }
        }
    }

    // MARK: - Vibration

    /// Must be called on main thread
    private func startVibration() {
        // Create a repeating timer for vibration
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.lock.lock()
            let shouldContinue = self._isPlaying
            self.lock.unlock()

            guard shouldContinue else {
                DispatchQueue.main.async {
                    self.vibrationTimer?.invalidate()
                    self.vibrationTimer = nil
                }
                return
            }

            // Trigger vibration
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        // Also trigger immediate vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // MARK: - Critical Alert Support

    /// Requests Critical Alert authorization for bypassing Do Not Disturb.
    /// This requires a special entitlement from Apple.
    func requestCriticalAlertAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            return granted
        } catch {
            print("Failed to request critical alert authorization: \(error)")
            return false
        }
    }
}
