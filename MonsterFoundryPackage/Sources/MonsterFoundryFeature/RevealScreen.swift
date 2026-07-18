import SwiftUI
import UIKit

struct RevealScreen: View {
    let result: MonsterResult
    let videoState: VideoGenerationState
    let speaker: MonsterSpeaker
    let onNarrateStory: () -> Void
    let onContinueStory: () -> Void
    let onNewScene: () -> Void
    let onReset: () -> Void
    let onOpenGallery: () -> Void
    let onRetryVideo: () -> Void
    let onGenerateMovie: (VideoLength) -> Void

    @State private var celebrateMovie = false

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height * 1.12
            let horizontalPadding: CGFloat = proxy.size.width > 900 ? 26 : 14
            let sidebarWidth = min(max(proxy.size.width * 0.29, 300), 410)
            let heroWidth = max(proxy.size.width - sidebarWidth - 18 - (horizontalPadding * 2), 280)
            let landscapeStageHeight = max(proxy.size.height - 160, 340)

            VStack(spacing: 16) {
                revealHeader

                if landscape {
                    HStack(alignment: .center, spacing: 18) {
                        HeroStage(result: result, videoState: videoState, showsCaption: false)
                            .frame(width: heroWidth, height: landscapeStageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                        ScrollView {
                            StoryPanel(
                                result: result,
                                videoState: videoState,
                                speaker: speaker,
                                onNarrateStory: onNarrateStory,
                                onContinueStory: onContinueStory,
                                onNewScene: onNewScene,
                                onGenerateMovie: onGenerateMovie
                            )
                        }
                        .scrollIndicators(.hidden)
                        .frame(width: sidebarWidth, height: landscapeStageHeight)
                    }
                    .frame(height: landscapeStageHeight)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            HeroStage(result: result, videoState: videoState, showsCaption: true)
                                .aspectRatio(16 / 9, contentMode: .fit)
                            StoryPanel(
                                result: result,
                                videoState: videoState,
                                speaker: speaker,
                                onNarrateStory: onNarrateStory,
                                onContinueStory: onContinueStory,
                                onNewScene: onNewScene,
                                onGenerateMovie: onGenerateMovie
                            )
                            footerActions
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                if landscape {
                    footerActions
                }
            }
            .frame(maxWidth: 1_440, maxHeight: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("monsterRevealScreen")
        .swConfetti(isActive: $celebrateMovie, particleCount: 64)
        .onChange(of: videoState) { _, state in
            if case .ready = state {
                celebrateMovie = true
            }
        }
    }

    private var revealHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("IT’S ALIVE!")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(2.2)
                    .foregroundStyle(MonsterTheme.mango)
                Text("Meet \(result.profile.name)")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onOpenGallery) {
                    Label("My Creations", systemImage: "rectangle.stack.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityIdentifier("revealGalleryButton")

                Button(action: onReset) {
                    Label("Draw another", systemImage: "plus")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(MonsterTheme.mango, in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(MonsterTheme.ink)
                .accessibilityIdentifier("drawAnotherButton")
            }
        }
    }

    @ViewBuilder
    private var footerActions: some View {
        if case .failed(let message) = videoState, !result.isFallback {
            HStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)
                VStack(alignment: .leading, spacing: 2) {
                    Text("The movie needs another moment")
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                    Text("Your picture, story, and voice are all ready to enjoy now — you can try the movie again any time.")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button(action: onRetryVideo) {
                    Label("Try again", systemImage: "arrow.clockwise")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(MonsterTheme.ink)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background(MonsterTheme.mango, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .monsterGlassPanel()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("The movie could not finish. \(message). Your picture and story are ready. Double tap to try the movie again.")
        }
    }
}

private struct HeroStage: View {
    let result: MonsterResult
    let videoState: VideoGenerationState
    let showsCaption: Bool

    @State private var reactionCount = 0
    @State private var isReacting = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroMedia
                .scaleEffect(isReacting ? 1.035 : 1)
                .rotationEffect(.degrees(isReacting ? 1.2 : 0))

            LinearGradient(
                colors: [.clear, .black.opacity(0.16), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            if showsCaption {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 7) {
                            Text(result.profile.species.uppercased())
                                .font(.system(.caption2, design: .rounded, weight: .black))
                                .tracking(1.5)
                            videoBadge
                        }
                        .foregroundStyle(.white.opacity(0.70))

                        Text("“\(result.profile.greeting)”")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Label("Tap the character to make it react", systemImage: "hand.tap.fill")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(MonsterTheme.mango)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(22)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isReacting {
                ZStack {
                    ForEach(0..<7, id: \.self) { index in
                        Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                            .font(.system(size: CGFloat(15 + (index % 3) * 5), weight: .black))
                            .foregroundStyle(index.isMultiple(of: 2) ? MonsterTheme.mango : MonsterTheme.mint)
                            .offset(
                                x: cos(Double(index) * .pi / 3.5) * 92,
                                y: sin(Double(index) * .pi / 3.5) * 72
                            )
                    }

                    VStack(spacing: 7) {
                        Image(systemName: reactionSymbol)
                            .font(.system(size: 42, weight: .black))
                        Text(reactionWord)
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .tracking(1.4)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(.black.opacity(0.58), in: Capsule())
                }
                .id(reactionCount)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
            }

            videoProgress

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: MonsterTheme.purple.opacity(0.30), radius: 30, y: 16)
        .contentShape(Rectangle())
        .onTapGesture { reactionCount += 1 }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: reactionCount)
        .task(id: reactionCount) {
            guard reactionCount > 0 else { return }
            withAnimation(.spring(response: 0.20, dampingFraction: 0.48)) { isReacting = true }
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { isReacting = false }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.profile.name), \(result.profile.species). Tap to make the character jump.")
        .accessibilityAddTraits(.isButton)
    }

    private var reactionWord: String {
        ["BOING!", "HELLO!", "ACHOO!", "TA-DA!", "WHEEE!", "AGAIN!"][reactionCount % 6]
    }

    private var reactionSymbol: String {
        ["arrow.up", "hand.wave.fill", "wind", "wand.and.stars", "figure.play", "repeat"][reactionCount % 6]
    }

    @ViewBuilder
    private var heroMedia: some View {
        if case .ready(let url) = videoState {
            LoopingVideoPlayer(url: url)
        } else if let data = result.heroImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            FallbackWorld(seed: result.seed)
        }
    }

}

private struct OriginalSeedCard: View {
    let seed: CreativeSeed

    var body: some View {
        VStack(spacing: 5) {
            if let data = seed.sketchData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(.white)
            } else {
                Text(seed.creaturePrompt)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(MonsterTheme.deepPurple)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text(seed.sketchData == nil ? "YOUR IDEA" : "YOUR SKETCH")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(MonsterTheme.ink)
        }
        .padding(7)
        .frame(width: 108, height: 112)
        .background(MonsterTheme.paper)
        .rotationEffect(.degrees(3))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .allowsHitTesting(false)
        .accessibilityLabel(seed.sketchData == nil ? "Original child idea" : "Original child sketch")
    }
}

private extension HeroStage {

    @ViewBuilder
    private var videoBadge: some View {
        switch videoState {
        case .requesting(let scene, let total), .processing(let scene, let total):
            Label("SCENE \(scene)/\(total)", systemImage: "film.fill")
                .foregroundStyle(MonsterTheme.mango)
        case .ready:
            Label("LIVING MOVIE", systemImage: "play.fill")
                .foregroundStyle(MonsterTheme.mint)
        case .idle:
            Label(result.brief.output.shortTitle.uppercased(), systemImage: result.brief.output.symbol)
                .foregroundStyle(MonsterTheme.mint)
        case .failed:
            EmptyView()
        }
    }

    @ViewBuilder
    private var videoProgress: some View {
        switch videoState {
        case .requesting(let scene, let total), .processing(let scene, let total):
            VStack(spacing: 8) {
                ProgressView()
                    .tint(MonsterTheme.mango)
                Text("Building movie scene \(scene) of \(total)")
                    .font(.system(.caption, design: .rounded, weight: .black))
                Text("The character is ready to play while the movie cooks.")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .opacity(0.58)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.black.opacity(0.60), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .allowsHitTesting(false)
        default:
            EmptyView()
        }
    }
}

private struct StoryPanel: View {
    let result: MonsterResult
    let videoState: VideoGenerationState
    let speaker: MonsterSpeaker
    let onNarrateStory: () -> Void
    let onContinueStory: () -> Void
    let onNewScene: () -> Void
    let onGenerateMovie: (VideoLength) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(result.brief.continuationContext == nil ? "THE STORY" : "THE NEXT CHAPTER")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .tracking(1.7)
                        .foregroundStyle(MonsterTheme.mango)
                    Text(result.profile.backstory)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                OriginalSeedCard(seed: result.seed)
                    .scaleEffect(0.82, anchor: .topTrailing)
                    .frame(width: 90, height: 94, alignment: .topTrailing)
            }

            Label("Tap the picture for a surprise reaction", systemImage: "hand.tap.fill")
                .font(.system(.caption2, design: .rounded, weight: .black))
                .foregroundStyle(MonsterTheme.mint)

            narrationControl

            Divider().overlay(.white.opacity(0.12))

            FactRow(symbol: "house.fill", label: "Lives in", value: result.profile.home, color: MonsterTheme.mint)
            FactRow(symbol: "fork.knife", label: "Eats", value: result.profile.favoriteFood, color: MonsterTheme.mango)
            FactRow(symbol: "exclamationmark.triangle.fill", label: "Secret fear", value: result.profile.fear, color: MonsterTheme.pink)
            FactRow(symbol: "bolt.heart.fill", label: "Personality", value: result.profile.personality, color: .purple.opacity(0.9))

            if !result.profile.visibleTraits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.seed.sketchData == nil ? "AI USED FROM YOUR IDEA" : "AI NOTICED IN THE DRAWING")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.44))
                    FlexibleTraits(traits: result.profile.visibleTraits)
                }
                .padding(.top, 3)
            }

            Divider().overlay(.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 9) {
                Text("THE CREATIVE RECIPE")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(MonsterTheme.mango)

                HStack(spacing: 6) {
                    CreativeChip(symbol: result.brief.medium.symbol, text: result.brief.medium.shortTitle)
                    CreativeChip(symbol: result.brief.output.symbol, text: result.brief.output.shortTitle)
                    CreativeChip(symbol: "book.pages", text: result.brief.storyLength.title)
                }

                CreativeChip(symbol: "scope", text: "\(result.brief.fidelity.title) to the original")

                if result.brief.output.includesVideo {
                    Label("\(result.brief.videoLength.rawValue)-second movie · \(result.brief.videoLength.sceneLabel)", systemImage: "film.stack.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.86))

                    ForEach(Array(result.profile.scenePrompts.prefix(result.brief.videoLength.sceneCount).enumerated()), id: \.offset) { index, scene in
                        Label("\(index + 1). \(scene)", systemImage: "sparkle")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(2)
                    }
                }
            }

            if result.isFallback {
                Label("Offline magic—check the Gemini key or connection for a generated world", systemImage: "wifi.slash")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.46))
            }

            if showsMovieMaker {
                Divider().overlay(.white.opacity(0.12))
                movieMaker
            }

            Divider().overlay(.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 9) {
                Text("KEEP THE ADVENTURE GOING")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.44))

                HStack(spacing: 8) {
                    adventureButton("Next chapter", symbol: "book.pages.fill", action: onContinueStory)
                    adventureButton("New scene", symbol: "movieclapper.fill", action: onNewScene)
                }
            }
        }
        .padding(22)
        .monsterGlassPanel()
    }

    /// Offer to make (or remake) a movie whenever one isn't already playing or
    /// being built — this is what lets a postcard or story become a movie after
    /// the fact. Hidden for the offline fallback, which has no hero image to
    /// animate.
    private var showsMovieMaker: Bool {
        guard !result.isFallback, result.heroImageData != nil else { return false }
        switch videoState {
        case .idle, .failed: return true
        case .requesting, .processing, .ready: return false
        }
    }

    private var movieMaker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hasExistingMovieChoice ? "TRY THE MOVIE AGAIN" : "MAKE IT A MOVIE")
                .font(.system(.caption2, design: .rounded, weight: .black))
                .tracking(1.4)
                .foregroundStyle(MonsterTheme.mango)

            Text("Bring \(result.profile.name) to life as a looping movie. Pick a length — longer movies use more scenes and take a little longer.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(VideoLength.allCases) { length in
                    Button {
                        onGenerateMovie(length)
                    } label: {
                        VStack(spacing: 2) {
                            Text(length.title)
                                .font(.system(.subheadline, design: .rounded, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                            Text(length.sceneLabel)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundStyle(MonsterTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(MonsterTheme.mango, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Make a \(length.rawValue) second movie")
                }
            }
        }
    }

    private var hasExistingMovieChoice: Bool {
        if case .failed = videoState { return true }
        return result.brief.output.includesVideo
    }

    private var narrationControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                if speaker.narrationState == .idle {
                    onNarrateStory()
                } else {
                    speaker.stop()
                }
            } label: {
                HStack(spacing: 9) {
                    if speaker.narrationState == .generating {
                        ProgressView()
                            .tint(MonsterTheme.ink)
                    } else {
                        Image(systemName: narrationSymbol)
                    }
                    Text(narrationTitle)
                    Spacer()
                    if speaker.narrationState != .idle && speaker.narrationState != .generating {
                        Text("STOP")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                }
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .foregroundStyle(MonsterTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(MonsterTheme.mango, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(speaker.narrationState == .idle ? "Listen to the story" : "Stop story narration")
            .accessibilityIdentifier("speakButton")

            Label("AI-generated narration when available · Apple voice fallback", systemImage: "info.circle.fill")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.44))
        }
    }

    private var narrationTitle: String {
        switch speaker.narrationState {
        case .idle: "Listen to the story"
        case .generating: "Creating the storyteller voice…"
        case .playingAI: "Playing AI storyteller"
        case .playingSystemFallback: "Playing Apple storyteller"
        }
    }

    private var narrationSymbol: String {
        switch speaker.narrationState {
        case .idle: "speaker.wave.3.fill"
        case .generating: "waveform"
        case .playingAI, .playingSystemFallback: "stop.fill"
        }
    }

    private func adventureButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(.white.opacity(0.86))
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CreativeChip: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.08), in: Capsule())
    }
}

private struct FactRow: View {
    let symbol: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MonsterTheme.ink)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.42))
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

private struct FlexibleTraits: View {
    let traits: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(traits, id: \.self) { trait in
                Label(trait, systemImage: "eye.fill")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.08), in: Capsule())
            }
        }
    }
}

private struct FallbackWorld: View {
    let seed: CreativeSeed

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.26, green: 0.12, blue: 0.55), Color(red: 0.93, green: 0.24, blue: 0.50), MonsterTheme.mango],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.20))
                .frame(width: 220)
                .offset(x: 170, y: -70)
            if let data = seed.sketchData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(40)
                    .blendMode(.multiply)
                    .shadow(color: .white.opacity(0.35), radius: 22)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 64, weight: .bold))
                    Text(seed.creaturePrompt)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }
                .foregroundStyle(.white)
                .padding(48)
            }
        }
    }
}
