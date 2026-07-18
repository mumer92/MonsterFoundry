import Foundation
import Testing
@testable import MonsterFoundryFeature

@Test func monsterProfileDecodesFromGeminiShape() throws {
    let json = #"""
    {
      "name": "Wobbleton",
      "species": "Signal Snuffler",
      "visibleTraits": ["one round eye", "three legs"],
      "personality": "Dramatically helpful",
      "home": "Inside a router",
      "favoriteFood": "Wi-Fi signals",
      "fear": "Charging cables",
      "backstory": "A doodle sneezed. Wobbleton appeared.",
      "greeting": "Hello, drawer!",
      "firstAction": "One hop",
      "imagePrompt": "Preserve the silhouette",
      "motionPrompt": "Blink and hop",
      "scenePrompts": ["Blink awake", "Chase a star", "Dance with a shadow", "Wave goodbye"]
    }
    """#.data(using: .utf8)!

    let profile = try JSONDecoder().decode(MonsterProfile.self, from: json)
    #expect(profile.name == "Wobbleton")
    #expect(profile.visibleTraits.count == 2)
    #expect(profile.scenePrompts.count == 4)
}

@Test func creativeChoicesMatchTheJudgeFacingFlow() {
    #expect(CreativeMedium.allCases.count == 8)
    #expect(CreativeMedium.allCases.map(\.title).contains("Paper cutout"))
    #expect(CreativeOutput.allCases.map(\.title) == [
        "Fast illustrated postcard", "Short story", "Animated movie", "Full adventure pack",
    ])
    #expect(VideoLength.allCases.map(\.rawValue) == [8, 10, 20, 30])
    #expect(VideoLength.quick.sceneCount == 1)
    #expect(VideoLength.quick.isQuick)
    #expect(VideoLength.thirty.sceneCount == 4)
    #expect(CreativeBrief.demo.storyLength == .short)
    #expect(StoryLength.allCases == [.short, .medium, .long])
}

@Test func drawingStudioOffersRichNamedColourFamilies() {
    #expect(DrawingPalette.allCases.count == 6)
    #expect(DrawingPalette.allCases.flatMap(\.swatches).count >= 50)
    #expect(DrawingPalette.crayonBox.swatches.contains { $0.name == "Sunshine" })
    #expect(DrawingPalette.cosmic.swatches.contains { $0.name == "Alien Mint" })
}

@Test func brushStudioOffersDistinctPencilKitTools() {
    #expect(DrawingTool.allCases.count == 8)
    #expect(DrawingTool.allCases.map(\.title).contains("Ink"))
    #expect(DrawingTool.allCases.map(\.title).contains("Sketch"))
    #expect(DrawingTool.allCases.map(\.title).contains("Watercolor"))
    for tool in DrawingTool.allCases {
        #expect(tool.widthRange.contains(tool.defaultWidth))
        #expect((0.1...1).contains(tool.defaultOpacity))
    }
}

@Test func fallbackIsSafeAndPlayable() {
    let profile = MonsterProfile.fallback(for: .clay)
    #expect(!profile.greeting.isEmpty)
    #expect(profile.backstory.count < 300)
    #expect(profile.visibleTraits.count <= 4)
    #expect(profile.scenePrompts.count == 4)
}

@Test func creativeBriefTunesGenerationPrompts() {
    var brief = CreativeBrief.demo
    brief.medium = .paperCutout
    brief.output = .animation
    brief.storyLength = .long
    brief.storyDirection = "It is trying to return a borrowed moonbeam."
    brief.videoLength = .twenty
    brief.sceneDirection = "The monster races a rolling blueberry."

    #expect(brief.promptContext.contains("Paper cutout"))
    #expect(brief.promptContext.contains("20 seconds"))
    #expect(brief.promptContext.contains("rolling blueberry"))
    #expect(brief.promptContext.contains("280–360 words"))
    #expect(brief.promptContext.contains("borrowed moonbeam"))
}

@Test func continuationPreservesTheOriginalIdentity() {
    let original = MonsterProfile.fallback(for: .storybook)
    let identity = ContinuationIdentity(profile: original)
    let wildlyDifferentChapter = MonsterProfile(
        name: "Wrong New Name",
        species: "Wrong Type",
        visibleTraits: ["new shape"],
        personality: "Different",
        home: "Elsewhere",
        favoriteFood: "Pebbles",
        fear: "Nothing",
        backstory: "A genuinely new chapter happens here.",
        greeting: "Welcome back!",
        firstAction: "Waves",
        imagePrompt: "A new scene",
        motionPrompt: "Wave once",
        scenePrompts: ["One", "Two", "Three", "Four"]
    )

    let continued = wildlyDifferentChapter.preservingIdentity(identity)
    #expect(continued.name == original.name)
    #expect(continued.personality == original.personality)
    #expect(continued.backstory == wildlyDifferentChapter.backstory)
    #expect(continued.scenePrompts == wildlyDifferentChapter.scenePrompts)
}

@Test func downloadedVideoPathCanBePlayedDirectly() {
    let client = MonsterAPIClient(apiKey: "test-key")
    let url = client.videoURL(path: "file:///tmp/monster.mp4")
    #expect(url?.isFileURL == true)
}
