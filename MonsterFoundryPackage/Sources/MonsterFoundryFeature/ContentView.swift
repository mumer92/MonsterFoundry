import PencilKit
import SwiftUI

public struct ContentView: View {
    @State private var phase: ExperiencePhase = .drawing
    @State private var galleryReturnPhase: ExperiencePhase = .drawing
    @State private var drawing = PKDrawing()
    @State private var inputMode: CreationInputMode = .draw
    @State private var creaturePrompt = ""
    @State private var drawingTool: DrawingTool = .ink
    @State private var inkColor = DrawingPalette.crayonBox.swatches[1].color
    @State private var selectedColorName = DrawingPalette.crayonBox.swatches[1].name
    @State private var drawingPalette: DrawingPalette = .crayonBox
    @State private var brushWidth = DrawingTool.ink.defaultWidth
    @State private var brushOpacity = DrawingTool.ink.defaultOpacity
    @State private var canvasCommand: CanvasCommand?
    @State private var brief: CreativeBrief = .demo
    @State private var activeSeed: CreativeSeed?
    @State private var generationJob: GenerationJob?
    @State private var generationError: String?
    @State private var result: MonsterResult?
    @State private var videoState: VideoGenerationState = .idle
    @State private var videoAttempt = 0
    @State private var allowsAutomaticVideo = false
    /// True once the child explicitly asks for a movie on the reveal, so a
    /// postcard or story (whose output does not include video) can still be
    /// animated on demand.
    @State private var videoRequested = false
    /// Overall movie-build progress, 0...1, driven by the scene polling loop and
    /// surfaced as a determinate bar on the reveal.
    @State private var videoProgress: Double = 0
    @State private var speaker = MonsterSpeaker()
    @State private var library = CreationLibrary()

    private let apiClient: MonsterAPIClient

    public init() {
        apiClient = MonsterAPIClient()
    }

    public var body: some View {
        ZStack {
            MonsterBackdrop()

            switch phase {
            case .drawing:
                DrawingScreen(
                    drawing: $drawing,
                    inputMode: $inputMode,
                    creaturePrompt: $creaturePrompt,
                    tool: $drawingTool,
                    inkColor: $inkColor,
                    selectedColorName: $selectedColorName,
                    palette: $drawingPalette,
                    brushWidth: $brushWidth,
                    brushOpacity: $brushOpacity,
                    canvasCommand: $canvasCommand,
                    onNext: openCreativeStudio,
                    onOpenGallery: { openGallery(returningTo: .drawing) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))

            case .customizing:
                if let activeSeed {
                    CreationStudioScreen(
                        seed: activeSeed,
                        brief: $brief,
                        onBack: returnToCreation,
                        onAwaken: startAwakening
                    )
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

            case .awakening:
                if let generationJob {
                    AwakeningScreen(
                        seed: generationJob.seed,
                        brief: generationJob.brief,
                        errorMessage: generationError,
                        onCancel: cancelAwakening,
                        onRetry: retryAwakening,
                        onFallback: revealFallback
                    )
                    .transition(.opacity)
                }

            case .reveal:
                if let result {
                    RevealScreen(
                        result: result,
                        videoState: videoState,
                        speaker: speaker,
                        onNarrateStory: narrateCurrentStory,
                        onContinueStory: continueCurrentStory,
                        onNewScene: createNewScene,
                        onReset: reset,
                        onOpenGallery: { openGallery(returningTo: .reveal) },
                        onRetryVideo: {
                            allowsAutomaticVideo = true
                            videoAttempt += 1
                        },
                        onGenerateMovie: { length in
                            requestMovie(length)
                        },
                        videoProgress: videoProgress
                    )
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                }

            case .gallery:
                MonsterGalleryScreen(
                    library: library,
                    onBack: closeGallery,
                    onSelect: openSavedCreation,
                    onContinueStory: { continueCreation($0, as: .story) },
                    onNewScene: { continueCreation($0, as: .scene) },
                    onMakeMovie: { makeMovie(from: $0, length: $1) }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .preferredColorScheme(.dark)
        .task(id: generationJob?.id) {
            await generateMonster()
        }
        .task(id: VideoTaskID(resultID: result?.id, attempt: videoAttempt)) {
            await generateVideoIfPossible()
        }
    }

    @MainActor
    private func openCreativeStudio() {
        let sketchData = inputMode == .draw ? drawing.monsterJPEGData() : nil
        let prompt = inputMode == .prompt ? creaturePrompt : ""
        let seed = CreativeSeed(sketchData: sketchData, creaturePrompt: prompt)
        guard seed.hasContent else { return }
        activeSeed = seed
        withAnimation(.easeInOut(duration: 0.38)) {
            phase = .customizing
        }
    }

    @MainActor
    private func returnToCreation() {
        withAnimation(.easeInOut(duration: 0.32)) {
            phase = .drawing
        }
    }

    @MainActor
    private func startAwakening() {
        guard let activeSeed else { return }
        generationError = nil
        result = nil
        videoState = .idle
        allowsAutomaticVideo = true
        videoRequested = false
        generationJob = GenerationJob(seed: activeSeed, brief: brief)
        withAnimation(.easeInOut(duration: 0.45)) {
            phase = .awakening
        }
    }

    @MainActor
    private func cancelAwakening() {
        generationJob = nil
        generationError = nil
        withAnimation(.easeInOut(duration: 0.30)) {
            phase = activeSeed == nil ? .drawing : .customizing
        }
    }

    @MainActor
    private func retryAwakening() {
        guard let oldJob = generationJob else { return }
        generationError = nil
        generationJob = GenerationJob(seed: oldJob.seed, brief: oldJob.brief)
    }

    @MainActor
    private func revealFallback() {
        guard let job = generationJob else { return }
        let fallback = MonsterResult(
            profile: .fallback(for: job.brief.medium),
            seed: job.seed,
            heroImageData: nil,
            heroImageMimeType: "image/jpeg",
            isFallback: true,
            brief: job.brief
        )
        result = fallback
        library.save(fallback)
        generationJob = nil
        generationError = nil
        videoState = .idle
        allowsAutomaticVideo = false
        videoRequested = false
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            phase = .reveal
        }
    }

    @MainActor
    private func reset() {
        speaker.stop()
        generationJob = nil
        generationError = nil
        result = nil
        videoState = .idle
        videoAttempt = 0
        allowsAutomaticVideo = false
        videoRequested = false
        drawing = PKDrawing()
        creaturePrompt = ""
        activeSeed = nil
        brief = .demo
        withAnimation(.easeInOut(duration: 0.38)) {
            phase = .drawing
        }
    }

    @MainActor
    private func openGallery(returningTo destination: ExperiencePhase) {
        galleryReturnPhase = destination
        withAnimation(.easeInOut(duration: 0.34)) {
            phase = .gallery
        }
    }

    @MainActor
    private func closeGallery() {
        withAnimation(.easeInOut(duration: 0.34)) {
            phase = galleryReturnPhase
        }
    }

    @MainActor
    private func openSavedCreation(_ creation: SavedCreation) {
        speaker.stop()
        result = library.result(for: creation)
        videoState = library.videoURL(for: creation).map(VideoGenerationState.ready) ?? .idle
        allowsAutomaticVideo = false
        videoRequested = false
        galleryReturnPhase = .drawing
        withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
            phase = .reveal
        }
    }

    @MainActor
    private func narrateCurrentStory() {
        guard let result else { return }
        let saved = library.creations.first { $0.id == result.id }
        let cachedURL = saved.flatMap(library.narrationURL)
        let narration = "\(result.profile.name). \(result.profile.backstory) \(result.profile.greeting)"

        speaker.narrate(narration, cachedURL: cachedURL) { temporaryURL in
            library.attachNarration(temporaryURL, to: result.id)
        }
    }

    @MainActor
    private func continueCurrentStory() {
        guard let result,
              let saved = library.creations.first(where: { $0.id == result.id }) else { return }
        continueCreation(saved, as: .story)
    }

    @MainActor
    private func createNewScene() {
        guard let result,
              let saved = library.creations.first(where: { $0.id == result.id }) else { return }
        continueCreation(saved, as: .scene)
    }

    @MainActor
    private func continueCreation(_ creation: SavedCreation, as kind: ContinuationKind) {
        speaker.stop()
        let original = library.result(for: creation)
        activeSeed = original.seed
        result = nil
        videoState = .idle
        allowsAutomaticVideo = false
        videoRequested = false
        generationError = nil

        var nextBrief = creation.brief
        nextBrief.continuationIdentity = ContinuationIdentity(profile: creation.profile)
        nextBrief.continuationContext = """
        Continue the existing character named \(creation.profile.name), described as \(creation.profile.species).
        Preserve the same design, visible traits, personality, home, favourite food, and harmless fear.
        Existing story: \(creation.profile.backstory)
        Existing greeting: \(creation.profile.greeting)
        """

        switch kind {
        case .story:
            nextBrief.output = .shortStory
            if nextBrief.storyLength == .short { nextBrief.storyLength = .medium }
            nextBrief.storyDirection = "Write the next chapter of \(creation.profile.name)'s adventure. Move the story forward with a new problem and payoff; do not repeat the origin."
        case .scene:
            nextBrief.output = .animation
            nextBrief.videoLength = .quick
            nextBrief.sceneDirection = SceneIdeas.random(excluding: nextBrief.sceneDirection)
            nextBrief.usesSurpriseScenes = true
        }

        brief = nextBrief
        galleryReturnPhase = .drawing
        withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
            phase = .customizing
        }
    }

    @MainActor
    private func generateMonster() async {
        guard let job = generationJob, phase == .awakening, generationError == nil else { return }

        do {
            let generated = try await apiClient.awaken(seed: job.seed, brief: job.brief)
            try Task.checkCancellation()
            result = generated
            library.save(generated)
            generationJob = nil
            withAnimation(.spring(response: 0.60, dampingFraction: 0.84)) {
                phase = .reveal
            }
            speaker.speak(generated.profile.greeting)
        } catch is CancellationError {
            return
        } catch {
            generationError = error.localizedDescription
        }
    }

    /// Requests a movie for the current creation on demand, even if its output
    /// was a postcard or story. Rebuilds the result with the chosen length and
    /// kicks the video task.
    /// Opens a saved creation on the reveal and immediately starts a fresh
    /// movie of the chosen length — the "make a movie" action from a gallery
    /// card.
    @MainActor
    private func makeMovie(from creation: SavedCreation, length: VideoLength) {
        openSavedCreation(creation)
        requestMovie(length)
    }

    @MainActor
    private func requestMovie(_ length: VideoLength) {
        guard let current = result,
              !current.isFallback,
              current.heroImageData != nil else { return }
        var updatedBrief = current.brief
        updatedBrief.output = .animation
        updatedBrief.videoLength = length
        let updatedResult = MonsterResult(
            id: current.id,
            createdAt: current.createdAt,
            profile: current.profile,
            seed: current.seed,
            heroImageData: current.heroImageData,
            heroImageMimeType: current.heroImageMimeType,
            isFallback: current.isFallback,
            brief: updatedBrief
        )
        result = updatedResult
        library.save(updatedResult)
        videoRequested = true
        allowsAutomaticVideo = true
        videoState = .idle
        videoProgress = 0
        videoAttempt += 1
    }

    @MainActor
    private func generateVideoIfPossible() async {
        guard let result,
              allowsAutomaticVideo,
              !result.isFallback,
              result.heroImageData != nil,
              result.brief.output.includesVideo || videoRequested,
              phase == .reveal else { return }

        let totalScenes = result.brief.videoLength.sceneCount
        var clips: [URL] = []
        defer {
            for clip in clips { try? FileManager.default.removeItem(at: clip) }
        }

        videoProgress = 0.02
        let sceneSpan = 1.0 / Double(max(1, totalScenes))

        do {
            for sceneIndex in 0..<totalScenes {
                try Task.checkCancellation()
                let displayScene = sceneIndex + 1
                let sceneBase = Double(sceneIndex) * sceneSpan
                videoProgress = sceneBase + sceneSpan * 0.05
                videoState = .requesting(scene: displayScene, total: totalScenes)
                let operation = try await apiClient.beginAnimation(
                    for: result,
                    scenePrompt: scenePrompt(for: result, index: sceneIndex)
                )
                videoState = .processing(scene: displayScene, total: totalScenes)

                var completedURL: URL?
                for pollIndex in 0..<45 {
                    try await Task.sleep(for: .seconds(4))
                    // Ease within this scene's slice toward ~92% while the clip
                    // renders, so the bar keeps moving during the long poll.
                    let within = 1 - pow(0.85, Double(pollIndex + 1))
                    videoProgress = sceneBase + sceneSpan * min(0.92, within)
                    let status = try await apiClient.animationStatus(operation: operation)
                    switch status.status {
                    case "complete":
                        guard let path = status.videoPath, let url = apiClient.videoURL(path: path) else {
                            throw MonsterAPIError.invalidResponse
                        }
                        completedURL = url
                    case "failed":
                        throw MonsterAPIError.server(status.message ?? "A tiny movie scene could not be created.")
                    default:
                        videoState = .processing(scene: displayScene, total: totalScenes)
                    }
                    if completedURL != nil { break }
                }
                guard let completedURL else {
                    throw MonsterAPIError.server("Scene \(displayScene) is taking longer than expected. Try the movie again later.")
                }
                clips.append(completedURL)
                videoProgress = Double(sceneIndex + 1) * sceneSpan
            }

            // Reserve the last sliver for the local join/trim step.
            videoProgress = 0.97
            let movieURL = try await VideoComposer.compose(
                clips: clips,
                targetDurationSeconds: result.brief.videoLength.rawValue
            )
            library.attachVideo(movieURL, to: result.id)
            if let saved = library.creations.first(where: { $0.id == result.id }),
               let permanentURL = library.videoURL(for: saved) {
                videoState = .ready(permanentURL)
                try? FileManager.default.removeItem(at: movieURL)
            } else {
                videoState = .ready(movieURL)
            }
            videoProgress = 1
        } catch is CancellationError {
            return
        } catch {
            videoState = .failed(error.localizedDescription)
        }
    }

    private func scenePrompt(for result: MonsterResult, index: Int) -> String {
        let prompts = result.profile.scenePrompts.isEmpty
            ? [result.profile.motionPrompt]
            : result.profile.scenePrompts
        let selected = prompts[index % prompts.count]
        return "Scene \(index + 1) of \(result.brief.videoLength.sceneCount): \(selected)"
    }
}

private struct VideoTaskID: Equatable {
    let resultID: UUID?
    let attempt: Int
}

private enum ContinuationKind {
    case story
    case scene
}

#Preview("Monster Foundry") {
    ContentView()
}
