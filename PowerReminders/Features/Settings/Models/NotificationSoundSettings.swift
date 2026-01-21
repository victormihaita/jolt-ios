import Foundation
import AVFoundation
import SwiftUI

@MainActor
class NotificationSoundSettings: ObservableObject {
    static let shared = NotificationSoundSettings()

    @AppStorage("selectedNotificationSound") var selectedSound: String = "gentle_chime"

    private var audioPlayer: AVAudioPlayer?

    // Sound definitions
    static let freeSounds: [(id: String, name: String)] = [
        ("gentle_chime", "Gentle Chime"),
        ("bell_ding", "Bell Ding"),
        ("soft_alert", "Soft Alert")
    ]

    static let premiumSounds: [(id: String, name: String)] = [
        ("crystal", "Crystal"),
        ("zen_bowl", "Zen Bowl"),
        ("nature_bird", "Nature Bird"),
        ("piano_note", "Piano Note")
    ]

    private init() {}

    var selectedSoundDisplayName: String {
        let allSounds = Self.freeSounds + Self.premiumSounds
        return allSounds.first { $0.id == selectedSound }?.name ?? "Gentle Chime"
    }

    func playPreview(_ soundId: String) {
        audioPlayer?.stop()

        guard let url = Bundle.main.url(forResource: soundId, withExtension: "wav")
                ?? Bundle.main.url(forResource: soundId, withExtension: "caf")
                ?? Bundle.main.url(forResource: soundId, withExtension: "m4a") else {
            Haptics.light()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
            Haptics.light()
        }
    }

    func selectSound(_ soundId: String, isPremium: Bool) -> Bool {
        let premiumSoundIds = Self.premiumSounds.map { $0.id }
        if premiumSoundIds.contains(soundId) && !isPremium {
            return false
        }
        selectedSound = soundId
        return true
    }
}
