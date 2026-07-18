import AVFoundation
import Foundation
import Observation

enum NarrationState: Equatable {
    case idle
    case generating
    case playingAI
    case playingSystemFallback
}

@MainActor
@Observable
final class MonsterSpeaker: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private(set) var narrationState: NarrationState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private let narrationClient = OpenAINarrationClient()
    private var audioPlayer: AVAudioPlayer?
    private var narrationTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stopPlaybackOnly()
        speakWithSystemVoice(text)
    }

    func narrate(
        _ text: String,
        cachedURL: URL?,
        onGenerated: @escaping @MainActor (URL) -> URL?
    ) {
        stop()

        if let cachedURL, playAudio(at: cachedURL) {
            narrationState = .playingAI
            return
        }

        narrationState = .generating
        narrationTask = Task {
            do {
                let data = try await narrationClient.generateStoryAudio(text: text)
                try Task.checkCancellation()
                let temporaryURL = FileManager.default.temporaryDirectory
                    .appending(path: "creation-narration-\(UUID().uuidString)")
                    .appendingPathExtension("mp3")
                try data.write(to: temporaryURL, options: .atomic)
                let playableURL = onGenerated(temporaryURL) ?? temporaryURL
                narrationState = playAudio(at: playableURL) ? .playingAI : .idle
                if playableURL != temporaryURL {
                    try? FileManager.default.removeItem(at: temporaryURL)
                }
            } catch is CancellationError {
                narrationState = .idle
            } catch {
                narrationState = .playingSystemFallback
                speakWithSystemVoice(text)
            }
        }
    }

    func stop() {
        narrationTask?.cancel()
        narrationTask = nil
        stopPlaybackOnly()
        narrationState = .idle
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.narrationState = .idle
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            if self?.narrationState == .playingSystemFallback {
                self?.narrationState = .idle
            }
        }
    }

    private func playAudio(at url: URL) -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            audioPlayer = player
            return player.play()
        } catch {
            audioPlayer = nil
            return false
        }
    }

    private func speakWithSystemVoice(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1.10
        utterance.volume = 1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }

    private func stopPlaybackOnly() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
