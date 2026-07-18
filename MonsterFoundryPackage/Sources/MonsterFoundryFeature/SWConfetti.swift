import SwiftUI

/// Lightweight, Canvas-based celebration overlay adapted from the ShipSwift
/// Confetti Burst recipe. It deliberately has no dependency and never blocks
/// touches on the creation underneath it.
struct SWConfetti<Content: View>: View {
    @Binding var isActive: Bool
    var particleCount = 56
    var colors: [Color] = [MonsterTheme.mango, MonsterTheme.mint, MonsterTheme.pink, .white, .purple]
    var duration = 2.6
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .overlay {
                SWConfettiCanvas(
                    isActive: $isActive,
                    particleCount: particleCount,
                    colors: colors,
                    duration: duration
                )
                .allowsHitTesting(false)
            }
    }
}

extension View {
    func swConfetti(
        isActive: Binding<Bool>,
        particleCount: Int = 56,
        duration: Double = 2.6
    ) -> some View {
        SWConfetti(
            isActive: isActive,
            particleCount: particleCount,
            duration: duration
        ) { self }
    }
}

private struct SWConfettiParticle {
    let x: Double
    let y: Double
    let velocityX: Double
    let velocityY: Double
    let rotation: Double
    let spin: Double
    let size: Double
    let color: Color
    let isCircle: Bool
}

private struct SWConfettiCanvas: View {
    @Binding var isActive: Bool
    let particleCount: Int
    let colors: [Color]
    let duration: Double

    @State private var particles: [SWConfettiParticle] = []
    @State private var startDate: Date?

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let startDate else { return }
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed <= duration else { return }

                let fade = elapsed < duration * 0.7
                    ? 1.0
                    : max(0, 1 - ((elapsed - duration * 0.7) / (duration * 0.3)))
                let canvasWidth = Double(size.width)
                let canvasHeight = Double(size.height)

                for particle in particles {
                    let x = (canvasWidth / 2) + particle.x + (particle.velocityX * elapsed)
                    let y = canvasHeight + particle.y + (particle.velocityY * elapsed) + (260 * elapsed * elapsed)
                    guard x > -30, x < canvasWidth + 30,
                          y > -30, y < canvasHeight + 80 else { continue }

                    let angle = Angle.degrees(particle.rotation + (particle.spin * elapsed))
                    let rect = CGRect(
                        x: CGFloat(x - (particle.size / 2)),
                        y: CGFloat(y - (particle.size / 2)),
                        width: CGFloat(particle.size),
                        height: CGFloat(particle.size * 0.72)
                    )

                    context.opacity = fade
                    context.translateBy(x: CGFloat(x), y: CGFloat(y))
                    context.rotate(by: angle)
                    context.translateBy(x: CGFloat(-x), y: CGFloat(-y))
                    if particle.isCircle {
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    } else {
                        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(particle.color))
                    }
                    context.translateBy(x: CGFloat(x), y: CGFloat(y))
                    context.rotate(by: .zero - angle)
                    context.translateBy(x: CGFloat(-x), y: CGFloat(-y))
                    context.opacity = 1
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active { launchBurst() }
        }
        .task {
            if isActive { launchBurst() }
        }
    }

    private func launchBurst() {
        guard !colors.isEmpty else { return }
        particles = (0..<particleCount).map { _ in
            let angle = -.pi / 2 + Double.random(in: -0.95...0.95)
            let speed = Double.random(in: 260...620)
            return SWConfettiParticle(
                x: Double.random(in: -24...24),
                y: Double.random(in: -8...14),
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                rotation: Double.random(in: 0...360),
                spin: Double.random(in: -520...520),
                size: Double.random(in: 6...13),
                color: colors.randomElement() ?? .white,
                isCircle: Bool.random()
            )
        }
        startDate = .now

        Task {
            try? await Task.sleep(for: .seconds(duration))
            isActive = false
        }
    }
}
