import SwiftUI

struct FoundryLaunchScreen: View {
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.05, blue: 0.14),
                    Color(red: 0.20, green: 0.06, blue: 0.42),
                    Color(red: 0.50, green: 0.09, blue: 0.44),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 1.0, green: 0.71, blue: 0.20).opacity(0.18))
                .frame(width: 330, height: 330)
                .blur(radius: 42)
                .scaleEffect(isBreathing ? 1.16 : 0.86)
                .offset(x: -110, y: -190)

            Circle()
                .fill(Color(red: 1.0, green: 0.25, blue: 0.57).opacity(0.22))
                .frame(width: 290, height: 290)
                .blur(radius: 52)
                .scaleEffect(isBreathing ? 0.86 : 1.12)
                .offset(x: 120, y: 230)

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 52, style: .continuous)
                        .fill(.white.opacity(0.10))
                        .frame(width: 210, height: 210)
                        .rotationEffect(.degrees(isBreathing ? 3 : -3))

                    Image("LaunchArt")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 182, height: 182)
                        .clipShape(RoundedRectangle(cornerRadius: 43, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 43, style: .continuous)
                                .stroke(Color.white.opacity(0.32), lineWidth: 1.5)
                        }
                        .shadow(color: Color(red: 1.0, green: 0.25, blue: 0.57).opacity(0.42), radius: 28, y: 14)
                        .scaleEffect(isBreathing ? 1.04 : 0.96)
                }

                VStack(spacing: 5) {
                    Text("MONSTER FOUNDRY")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .tracking(3.1)
                        .foregroundStyle(Color(red: 1.0, green: 0.71, blue: 0.20))
                    Text("Every scribble has a story.")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 1 ? Color(red: 0.35, green: 0.96, blue: 0.76) : .white.opacity(0.42))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isBreathing && index == 1 ? 1.45 : 1)
                    }
                }
            }
            .padding(32)
        }
        .task {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monster Foundry is waking up")
    }
}
