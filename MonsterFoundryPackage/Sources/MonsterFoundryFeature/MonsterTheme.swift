import SwiftUI

enum MonsterTheme {
    static let ink = Color(red: 0.08, green: 0.05, blue: 0.14)
    static let deepPurple = Color(red: 0.16, green: 0.07, blue: 0.31)
    static let purple = Color(red: 0.45, green: 0.20, blue: 0.93)
    static let pink = Color(red: 1.00, green: 0.25, blue: 0.57)
    static let mango = Color(red: 1.00, green: 0.71, blue: 0.20)
    static let mint = Color(red: 0.35, green: 0.96, blue: 0.76)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.96)
}

struct MonsterBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [MonsterTheme.ink, MonsterTheme.deepPurple, Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(MonsterTheme.purple.opacity(0.45))
                    .frame(width: proxy.size.width * 0.58)
                    .blur(radius: 90)
                    .offset(x: -proxy.size.width * 0.36, y: -proxy.size.height * 0.34)

                Circle()
                    .fill(MonsterTheme.pink.opacity(0.22))
                    .frame(width: proxy.size.width * 0.46)
                    .blur(radius: 100)
                    .offset(x: proxy.size.width * 0.40, y: proxy.size.height * 0.30)

                Canvas { context, size in
                    let dots: [(Double, Double, Double)] = [
                        (0.08, 0.14, 3), (0.18, 0.76, 2), (0.28, 0.28, 1.5),
                        (0.42, 0.10, 2), (0.52, 0.83, 3), (0.64, 0.22, 1.5),
                        (0.74, 0.68, 2), (0.84, 0.12, 3), (0.92, 0.46, 1.5),
                        (0.36, 0.61, 1.5), (0.67, 0.92, 2), (0.96, 0.87, 2.5),
                    ]
                    for dot in dots {
                        let rect = CGRect(
                            x: size.width * dot.0,
                            y: size.height * dot.1,
                            width: dot.2,
                            height: dot.2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.55)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct GlassPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
    }
}

extension View {
    func monsterGlassPanel() -> some View {
        modifier(GlassPanelModifier())
    }
}

struct PrimaryMonsterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .black))
            .foregroundStyle(MonsterTheme.ink)
            .padding(.horizontal, 24)
            .frame(minHeight: 58)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [MonsterTheme.mango, Color(red: 1, green: 0.48, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: MonsterTheme.mango.opacity(0.28), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
