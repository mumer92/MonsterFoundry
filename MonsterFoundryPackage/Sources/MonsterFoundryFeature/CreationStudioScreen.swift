import SwiftUI
import UIKit

struct CreationStudioScreen: View {
    let seed: CreativeSeed
    @Binding var brief: CreativeBrief
    let onBack: () -> Void
    let onAwaken: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height * 1.12

            VStack(spacing: 14) {
                header

                if landscape {
                    HStack(alignment: .top, spacing: 18) {
                        seedPreview
                            .frame(maxWidth: proxy.size.width * 0.42, maxHeight: .infinity)
                        configurationScroll(showPreview: false)
                    }
                } else {
                    configurationScroll(showPreview: true)
                }
            }
            .frame(maxWidth: 1_360, maxHeight: .infinity)
            .padding(.horizontal, proxy.size.width > 650 ? 26 : 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("creationStudioScreen")
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.09), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel("Back to creation")

            VStack(alignment: .leading, spacing: 2) {
                Text("DIRECT THE MAGIC")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(2)
                    .foregroundStyle(MonsterTheme.mango)
                Text("How should your idea come alive?")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            JudgeStep(number: "2", text: "Choose")
        }
    }

    private func configurationScroll(showPreview: Bool) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if brief.continuationContext != nil {
                    Label("You’re continuing an existing creation—its identity and personality will stay consistent.", systemImage: "arrow.triangle.branch")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(MonsterTheme.mint)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .background(MonsterTheme.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }

                if showPreview {
                    seedPreview
                        .containerRelativeFrame(.horizontal) { width, _ in
                            min(width, 720)
                        }
                        .frame(maxHeight: 320)
                }

                mediumPanel
                fidelityPanel
                outputPanel
                storyPanel

                if brief.output.includesVideo {
                    moviePanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button(action: onAwaken) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("BRING IT ALIVE")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(PrimaryMonsterButtonStyle())
                .accessibilityIdentifier("createMonsterButton")

                Text(brief.output.includesVideo
                     ? "The illustration appears first. Movie scenes cook in the background and are saved to My Creations."
                     : "Your finished character and story are saved automatically to My Creations.")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.46))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var seedPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(MonsterTheme.paper)

            if let data = seed.sketchData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(26)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(MonsterTheme.purple)
                    Text(seed.creaturePrompt)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(MonsterTheme.deepPurple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }

            Label(seed.sketchData == nil ? "YOUR IDEA" : "YOUR ORIGINAL", systemImage: seed.sketchData == nil ? "text.bubble.fill" : "scribble.variable")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(MonsterTheme.deepPurple.opacity(0.55))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.72), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(14)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    private var mediumPanel: some View {
        StudioPanel(title: "CHOOSE THE ART MATERIAL", subtitle: "The generated world uses this physical look.") {
            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    ForEach(CreativeMedium.allCases) { medium in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                brief.medium = medium
                            }
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: medium.symbol)
                                    .font(.system(size: 19, weight: .bold))
                                Text(medium.shortTitle)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(brief.medium == medium ? MonsterTheme.ink : .white.opacity(0.78))
                            .frame(width: 94, height: 66)
                            .background(
                                brief.medium == medium ? MonsterTheme.mango : .white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(brief.medium == medium ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var fidelityPanel: some View {
        StudioPanel(title: "HOW CLOSE TO THE ORIGINAL?", subtitle: brief.fidelity.summary) {
            HStack(spacing: 7) {
                ForEach(SketchFidelity.allCases) { fidelity in
                    Button {
                        brief.fidelity = fidelity
                    } label: {
                        Text(fidelity.title)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .foregroundStyle(brief.fidelity == fidelity ? MonsterTheme.ink : .white.opacity(0.72))
                            .background(
                                brief.fidelity == fidelity ? MonsterTheme.mint : .white.opacity(0.07),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var outputPanel: some View {
        StudioPanel(title: "WHAT SHOULD WE MAKE?", subtitle: "Choose the payoff before generation starts.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 285), spacing: 9)], spacing: 9) {
                ForEach(CreativeOutput.allCases) { output in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                            brief.output = output
                        }
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: output.symbol)
                                .font(.title3.weight(.bold))
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(output.title)
                                    .font(.system(.subheadline, design: .rounded, weight: .black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Text(output.subtitle)
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .opacity(0.62)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 2)
                            if brief.output == output {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .foregroundStyle(brief.output == output ? MonsterTheme.ink : .white.opacity(0.82))
                        .padding(.horizontal, 13)
                        .frame(minHeight: 66)
                        .background(
                            brief.output == output ? MonsterTheme.mango : .white.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var storyPanel: some View {
        StudioPanel(title: "SHAPE THE STORY", subtitle: "Optional—leave the idea blank and the character will surprise you.") {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 7) {
                    ForEach(StoryLength.allCases) { length in
                        Button {
                            brief.storyLength = length
                        } label: {
                            VStack(spacing: 2) {
                                Text(length.title)
                                    .font(.system(.subheadline, design: .rounded, weight: .black))
                                Text(length == .short ? "~60 words" : length == .medium ? "~160 words" : "~320 words")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .opacity(0.58)
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(brief.storyLength == length ? MonsterTheme.ink : .white.opacity(0.76))
                            .background(
                                brief.storyLength == length ? MonsterTheme.mint : .white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(brief.storyLength.subtitle)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)

                VStack(alignment: .leading, spacing: 7) {
                    Label("Background or story idea", systemImage: "book.pages.fill")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(.white.opacity(0.68))

                    TextEditor(text: $brief.storyDirection)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 88)
                        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            if brief.storyDirection.isEmpty {
                                Text("Example: It was built from a lonely lunchbox and wants to find the person who drew its missing wheel.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.28))
                                    .padding(14)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityIdentifier("storyDirectionEditor")
                }
            }
        }
    }

    private var moviePanel: some View {
        StudioPanel(title: "DIRECT THE MOVIE", subtitle: "Long movies are joined from coherent eight-second scenes.") {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 8) {
                    ForEach(VideoLength.allCases) { length in
                        Button {
                            brief.videoLength = length
                        } label: {
                            VStack(spacing: 2) {
                                Text(length.title)
                                    .font(.system(.headline, design: .rounded, weight: .black))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.62)
                                Text(length.sceneLabel)
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .opacity(0.58)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(brief.videoLength == length ? MonsterTheme.ink : .white.opacity(0.78))
                            .background(
                                brief.videoLength == length ? MonsterTheme.mint : .white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(brief.videoLength.waitHint)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(MonsterTheme.mango)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Describe the scene", systemImage: "movieclapper.fill")
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(.white.opacity(0.68))
                        Spacer()
                        Button {
                            brief.sceneDirection = SceneIdeas.random(excluding: brief.sceneDirection)
                            brief.usesSurpriseScenes = true
                        } label: {
                            Label("Surprise me", systemImage: "dice.fill")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(MonsterTheme.mango)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("randomSceneButton")
                    }

                    TextEditor(text: sceneDirectionBinding)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 92)
                        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            if brief.sceneDirection.isEmpty {
                                Text("Example: It chases a glowing hiccup, jumps over a teacup, then dances with its shadow.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.28))
                                    .padding(14)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
        }
    }

    private var sceneDirectionBinding: Binding<String> {
        Binding(
            get: { brief.sceneDirection },
            set: {
                brief.sceneDirection = $0
                brief.usesSurpriseScenes = false
            }
        )
    }
}

private struct StudioPanel<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.56))
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
            }
            content
        }
        .padding(15)
        .monsterGlassPanel()
    }
}
