import AVFoundation
import Foundation
import Observation

enum NarrationState: Equatable {
    case idle
    case generating
    case playingAI
    case playingSystemFallback
}

/// The storyteller voices offered for AI narration. Each maps to an OpenAI TTS
/// voice; the system fallback ignores the choice and uses an Apple voice.
enum StoryVoice: String, CaseIterable, Identifiable, Sendable {
    case marin
    case coral
    case sage
    case alloy
    case onyx

    var id: String { rawValue }

    /// The default that matches the app's original narration.
    static let `default` = StoryVoice.marin

    var apiValue: String { rawValue }

    var title: String {
        switch self {
        case .marin: "Marin"
        case .coral: "Coral"
        case .sage: "Sage"
        case .alloy: "Alloy"
        case .onyx: "Onyx"
        }
    }

    var blurb: String {
        switch self {
        case .marin: "Warm & playful"
        case .coral: "Bright & bubbly"
        case .sage: "Calm & gentle"
        case .alloy: "Clear & friendly"
        case .onyx: "Deep & cosy"
        }
    }

    var symbol: String { "waveform.circle.fill" }
}

@MainActor
@Observable
final class MonsterSpeaker: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private(set) var narrationState: NarrationState = .idle
    /// True while narration is loaded but paused.
    private(set) var isPaused = false
    /// Playback position, 0...1, for the scrubber and highlighting.
    private(set) var progress: Double = 0
    /// The sentences currently being narrated, for on-screen highlighting.
    private(set) var sentences: [String] = []
    /// The sentence currently being read, or -1 when none.
    private(set) var currentSentenceIndex = -1

    /// The chosen storyteller voice. Changing it does not interrupt playback;
    /// it applies to the next narration.
    var selectedVoice: StoryVoice = .default

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var narrationTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    /// Character start offset of each sentence, for mapping progress → sentence.
    private var sentenceOffsets: [Int] = []
    private var totalCharacters = 1

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    var isActive: Bool {
        narrationState == .playingAI || narrationState == .playingSystemFallback
    }

    var isPlaying: Bool { isActive && !isPaused }

    /// Whether the current playback supports scrubbing (AI audio only; the
    /// system speech fallback can pause but not seek).
    var supportsScrubbing: Bool { narrationState == .playingAI }

    func speak(_ text: String) {
        stopPlaybackOnly()
        prepareSentences(from: text)
        speakWithSystemVoice(text)
    }

    func narrate(
        _ text: String,
        cachedURL: URL?,
        onGenerated: @escaping @MainActor (URL) -> URL?
    ) {
        stop()
        prepareSentences(from: text)

        // The cache is only valid for the default voice; any other choice must
        // regenerate so the audio actually matches the selection.
        if selectedVoice == .default, let cachedURL, playAudio(at: cachedURL) {
            narrationState = .playingAI
            startProgressTracking()
            return
        }

        narrationState = .generating
        let voice = selectedVoice
        narrationTask = Task {
            do {
                let data = try await OpenAINarrationClient().generateStoryAudio(
                    text: text,
                    voice: voice.apiValue
                )
                try Task.checkCancellation()
                let temporaryURL = FileManager.default.temporaryDirectory
                    .appending(path: "creation-narration-\(UUID().uuidString)")
                    .appendingPathExtension("mp3")
                try data.write(to: temporaryURL, options: .atomic)
                // Only persist the default voice as the creation's cached
                // narration; alternate voices play but do not overwrite it.
                let playableURL = (voice == .default ? onGenerated(temporaryURL) : nil) ?? temporaryURL
                if playAudio(at: playableURL) {
                    narrationState = .playingAI
                    startProgressTracking()
                } else {
                    narrationState = .idle
                }
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

    func pause() {
        guard isActive, !isPaused else { return }
        switch narrationState {
        case .playingAI: audioPlayer?.pause()
        case .playingSystemFallback: synthesizer.pauseSpeaking(at: .word)
        default: break
        }
        isPaused = true
    }

    func resume() {
        guard isActive, isPaused else { return }
        switch narrationState {
        case .playingAI:
            audioPlayer?.play()
            startProgressTracking()
        case .playingSystemFallback:
            synthesizer.continueSpeaking()
        default: break
        }
        isPaused = false
    }

    func togglePlayPause() {
        if isPaused { resume() } else { pause() }
    }

    /// Seeks AI narration to a fraction of its duration. No-op for the system
    /// voice, which cannot seek.
    func seek(toFraction fraction: Double) {
        guard narrationState == .playingAI, let player = audioPlayer, player.duration > 0 else { return }
        let clamped = min(1, max(0, fraction))
        player.currentTime = clamped * player.duration
        progress = clamped
        updateSentence(forFraction: clamped)
    }

    func stop() {
        narrationTask?.cancel()
        narrationTask = nil
        progressTask?.cancel()
        progressTask = nil
        stopPlaybackOnly()
        narrationState = .idle
        isPaused = false
        progress = 0
        currentSentenceIndex = -1
    }

    // MARK: Sentence mapping

    private func prepareSentences(from text: String) {
        var pieces: [String] = []
        var offsets: [Int] = []
        let full = text as NSString
        text.enumerateSubstrings(
            in: text.startIndex..<text.endIndex,
            options: [.bySentences, .localized]
        ) { substring, range, _, _ in
            let trimmed = substring?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { return }
            pieces.append(trimmed)
            offsets.append(full.range(of: substring ?? "").location)
        }
        if pieces.isEmpty {
            pieces = [text.trimmingCharacters(in: .whitespacesAndNewlines)]
            offsets = [0]
        }
        sentences = pieces
        sentenceOffsets = offsets
        totalCharacters = max(1, text.count)
        currentSentenceIndex = -1
    }

    private func updateSentence(forFraction fraction: Double) {
        guard !sentences.isEmpty else { currentSentenceIndex = -1; return }
        let charPosition = Int(fraction * Double(totalCharacters))
        var index = 0
        for (i, offset) in sentenceOffsets.enumerated() where offset <= charPosition {
            index = i
        }
        currentSentenceIndex = index
    }

    private func startProgressTracking() {
        progressTask?.cancel()
        progressTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let player = audioPlayer else { break }
                if player.duration > 0 {
                    progress = min(1, player.currentTime / player.duration)
                    updateSentence(forFraction: progress)
                }
                if narrationState != .playingAI { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    // MARK: Delegates

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.progress = 1
            self?.currentSentenceIndex = -1
            self?.narrationState = .idle
            self?.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.narrationState == .playingSystemFallback else { return }
            self.progress = 1
            self.currentSentenceIndex = -1
            self.narrationState = .idle
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let location = characterRange.location
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.progress = min(1, Double(location) / Double(self.totalCharacters))
            self.updateSentence(forFraction: self.progress)
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
            progress = 0
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
