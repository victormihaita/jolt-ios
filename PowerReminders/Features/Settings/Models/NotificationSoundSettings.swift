import Foundation
import AVFoundation
import SwiftUI
import PRNetworking

/// Represents a notification sound from the backend
struct NotificationSoundItem: Identifiable, Hashable {
    let id: String
    let name: String
    let filename: String
    let isFree: Bool
}

@MainActor
class NotificationSoundSettings: ObservableObject {
    static let shared = NotificationSoundSettings()

    @AppStorage("selectedNotificationSound") var selectedSound: String = "ambient.wav"

    @Published var sounds: [NotificationSoundItem] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private var audioPlayer: AVAudioPlayer?
    private let graphQL = GraphQLClient.shared

    /// Default fallback sounds in case backend is unreachable
    private static let fallbackSounds: [NotificationSoundItem] = [
        NotificationSoundItem(id: "1", name: "Ambient", filename: "ambient.wav", isFree: true),
        NotificationSoundItem(id: "2", name: "Hop", filename: "hop.wav", isFree: true),
        NotificationSoundItem(id: "3", name: "Rock", filename: "rock.wav", isFree: true),
        NotificationSoundItem(id: "4", name: "Ambient Soft", filename: "ambient2.wav", isFree: false),
        NotificationSoundItem(id: "5", name: "Progressive", filename: "progressive.wav", isFree: false),
        NotificationSoundItem(id: "6", name: "Reverb", filename: "reverb.wav", isFree: false),
        NotificationSoundItem(id: "7", name: "Synth Pop", filename: "syntpop.wav", isFree: false),
        NotificationSoundItem(id: "8", name: "Techno", filename: "techno.wav", isFree: false),
    ]

    private init() {
        // Load fallback sounds initially
        sounds = Self.fallbackSounds
    }

    var freeSounds: [NotificationSoundItem] {
        sounds.filter { $0.isFree }
    }

    var premiumSounds: [NotificationSoundItem] {
        sounds.filter { !$0.isFree }
    }

    var selectedSoundDisplayName: String {
        sounds.first { $0.filename == selectedSound }?.name ?? "Ambient"
    }

    /// Fetch sounds from backend
    func fetchSounds() async {
        isLoading = true
        loadError = nil

        do {
            let query = PRAPI.NotificationSoundsQuery()
            let result = try await graphQL.fetch(query: query)

            let fetchedSounds = result.notificationSounds.map { sound in
                NotificationSoundItem(
                    id: sound.id,
                    name: sound.name,
                    filename: sound.filename,
                    isFree: sound.isFree
                )
            }

            if !fetchedSounds.isEmpty {
                sounds = fetchedSounds

                // Ensure selected sound is valid, otherwise reset to first free sound
                if !sounds.contains(where: { $0.filename == selectedSound }) {
                    selectedSound = freeSounds.first?.filename ?? "ambient.wav"
                }
            }

            isLoading = false
        } catch {
            print("Failed to fetch notification sounds: \(error)")
            loadError = "Failed to load sounds"
            isLoading = false
            // Keep using fallback sounds
        }
    }

    func playPreview(_ filename: String) {
        audioPlayer?.stop()

        // Extract the base name without extension for Bundle lookup
        let baseName = (filename as NSString).deletingPathExtension

        // Try to load sound file from bundle
        if let url = Bundle.main.url(forResource: baseName, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                Haptics.light()
                return
            } catch {
                print("Failed to play sound \(filename): \(error)")
            }
        }

        // Fallback - play haptic only
        print("Sound file not found in bundle: \(filename)")
        Haptics.medium()
    }

    func selectSound(_ filename: String, isPremium: Bool) -> Bool {
        // Check if this is a premium sound and user doesn't have premium
        if let sound = sounds.first(where: { $0.filename == filename }) {
            if !sound.isFree && !isPremium {
                return false
            }
        }
        selectedSound = filename
        return true
    }
}
