import SwiftUI
import MonsterFoundryFeature

@main
struct MonsterFoundryApp: App {
    @State private var showsLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showsLaunchScreen {
                    FoundryLaunchScreen()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .task {
                guard showsLaunchScreen else { return }
                try? await Task.sleep(for: .milliseconds(1_150))
                withAnimation(.easeOut(duration: 0.26)) {
                    showsLaunchScreen = false
                }
            }
        }
    }
}
