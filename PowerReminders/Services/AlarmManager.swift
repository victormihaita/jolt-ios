import AVFoundation
import UIKit
import AudioToolbox

/// Manages alarm sound playback and vibration for reminder notifications.
/// Supports playing alarm sounds that can be stopped from any device via cross-device sync.
class AlarmManager {
    static let shared = AlarmManager()

    private var audioPlayer: AVAudioPlayer?
    private var isPlaying = false
    private var vibrationTimer: Timer?
    private var currentReminderID: UUID?

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
    /// - Parameters:
    ///   - reminderID: The ID of the reminder triggering the alarm
    ///   - soundName: The name of the sound file to play (without extension)
    ///   - vibrate: Whether to also trigger vibration
    func startAlarm(
        for reminderID: UUID,
        soundName: String = "alarm_default",
        vibrate: Bool = true
    ) {
        // Don't start a new alarm if one is already playing
        guard !isPlaying else { return }

        currentReminderID = reminderID
        isPlaying = true

        // Try to play custom sound, fall back to system sound
        if !playCustomSound(named: soundName) {
            playSystemAlarmSound()
        }

        // Start vibration if enabled
        if vibrate {
            startVibration()
        }

        print("Started alarm for reminder: \(reminderID)")
    }

    /// Stops the currently playing alarm.
    func stopAlarm() {
        guard isPlaying else { return }

        // Stop audio
        audioPlayer?.stop()
        audioPlayer = nil

        // Stop vibration
        stopVibration()

        isPlaying = false

        if let reminderID = currentReminderID {
            print("Stopped alarm for reminder: \(reminderID)")
        }

        currentReminderID = nil
    }

    /// Returns the ID of the reminder for which the alarm is currently playing.
    var currentAlarmReminderID: UUID? {
        return isPlaying ? currentReminderID : nil
    }

    /// Returns whether an alarm is currently playing.
    var isAlarmPlaying: Bool {
        return isPlaying
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
        // Play system alarm sound on loop
        // Using AudioServicesPlaySystemSound for system sounds
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while self?.isPlaying == true {
                AudioServicesPlaySystemSound(1005) // Default alarm sound
                Thread.sleep(forTimeInterval: 1.5) // Wait before repeating
            }
        }
    }

    // MARK: - Vibration

    private func startVibration() {
        // Create a repeating timer for vibration
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard self?.isPlaying == true else {
                self?.stopVibration()
                return
            }

            // Trigger vibration
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        // Also trigger immediate vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func stopVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
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
