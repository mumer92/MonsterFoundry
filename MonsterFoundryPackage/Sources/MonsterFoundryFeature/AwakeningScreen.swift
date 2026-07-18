import SwiftUI
import UIKit

struct AwakeningScreen: View {
    let seed: CreativeSeed
    let brief: CreativeBrief
    let errorMessage: String?
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onFallback: () -> Void

    @State private var stageIndex = 0
    @State private var isPulsing = false

    private let stages = [
        "Reading every wonderful wobble…",
        "Discovering a very strange personality…",
        "Building its first impossible world…",
        "Planning the character's funniest scene…",
    ]

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height * 1.12

            Group {
                if landscape {
                    HStack(spacing: 54) {
                        magicVisual
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        statusPanel
                            .frame(maxWidth: 520)
                    }
                } else {
                    VStack(spacing: 26) {
                        Spacer(minLength: 18)
                        magicVisual
                        statusPanel
                        Spacer(minLength: 18)
                    }
                }
            }
            .padding(.horizontal, landscape ? 60 : 24)
            .frame(maxWidth: 1_220, maxHeight: .infinity)
            .frame(maxWidth: .infinity)
        }
        .task {
            isPulsing = true
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1.8))
                } catch {
                    return
                }
                guard errorMessage == nil else { continue }
                withAnimation(.easeInOut(duration: 0.35)) {
                    stageIndex = (stageIndex + 1) % stages.count
                }
            }
        }
        .accessibilityIdentifier("awakeningScreen")
    }

    private var magicVisual: some View {
        ZStack {
            Circle()
                .stroke(MonsterTheme.purple.opacity(0.40), lineWidth: 2)
                .frame(width: 330, height: 330)
                .scaleEffect(isPulsing ? 1.10 : 0.88)
                .opacity(isPulsing ? 0.10 : 0.72)

            Circle()
                .fill(MonsterTheme.pink.opacity(0.20))
                .frame(width: 245, height: 245)
                .blur(radius: 30)
                .scaleEffect(isPulsing ? 1.14 : 0.90)

            seedCard
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(isPulsing ? 2.5 : -2.5))
                .scaleEffect(isPulsing ? 1.03 : 0.97)
                .shadow(color: MonsterTheme.purple.opacity(0.45), radius: 35)

            ForEach(0..<6, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                    .font(.system(size: CGFloat(12 + index * 2), weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? MonsterTheme.mango : MonsterTheme.mint)
                    .offset(x: cos(Double(index) * .pi / 3) * 154, y: sin(Double(index) * .pi / 3) * 154)
                    .rotationEffect(.degrees(isPulsing ? 90 : 0))
            }
        }
        .frame(width: 370, height: 370)
        .animation(.easeInOut(duration: 1.55).repeatForever(autoreverses: true), value: isPulsing)
    }

    @ViewBuilder
    private var seedCard: some View {
        if let data = seed.sketchData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(24)
                .background(MonsterTheme.paper, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(MonsterTheme.purple)
                Text(seed.creaturePrompt)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(MonsterTheme.deepPurple)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MonsterTheme.paper, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        }
    }

    private var statusPanel: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text(errorMessage == nil ? "YOUR IDEA IS WAKING UP" : "THE MAGIC HIT A BUMP")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(2.3)
                    .foregroundStyle(errorMessage == nil ? MonsterTheme.mango : MonsterTheme.pink)

                Text(errorMessage == nil ? stages[stageIndex] : "Your idea is safe.")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                        .multilineTextAlignment(.center)
                } else {
                    Label("Creating \(brief.medium.title.lowercased()) art and a personality", systemImage: brief.medium.symbol)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.54))
                        .multilineTextAlignment(.center)
                }
            }

            if errorMessage != nil {
                VStack(spacing: 11) {
                    Button("Try the magic again", action: onRetry)
                        .buttonStyle(PrimaryMonsterButtonStyle())
                    Button("Reveal a playful offline version", action: onFallback)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                    Button("Back to choices", action: onCancel)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.60))
                }
            } else {
                Button("Cancel", action: onCancel)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
    }
}
