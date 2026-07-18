import Foundation

enum CreationInputMode: String, CaseIterable, Identifiable, Sendable {
    case draw
    case prompt

    var id: Self { self }

    var title: String {
        switch self {
        case .draw: "Draw"
        case .prompt: "Use a prompt"
        }
    }

    var symbol: String {
        switch self {
        case .draw: "applepencil.and.scribble"
        case .prompt: "text.bubble.fill"
        }
    }
}

struct CreativeSeed: Codable, Equatable, Sendable {
    var sketchData: Data?
    var creaturePrompt: String

    var hasContent: Bool {
        sketchData != nil || creaturePrompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var promptDescription: String {
        let trimmed = creaturePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Use the supplied child's sketch as the main character or subject design." : String(trimmed.prefix(300))
    }
}

enum CreativeMedium: String, CaseIterable, Codable, Identifiable, Sendable {
    case ink
    case graphite
    case crayon
    case watercolor
    case marker
    case paperCutout
    case clay
    case storybook

    var id: Self { self }

    var title: String {
        switch self {
        case .ink: "Ink drawing"
        case .graphite: "Pencil sketch"
        case .crayon: "Crayon"
        case .watercolor: "Watercolor"
        case .marker: "Marker"
        case .paperCutout: "Paper cutout"
        case .clay: "Clay"
        case .storybook: "Storybook"
        }
    }

    var shortTitle: String {
        switch self {
        case .ink: "Ink"
        case .graphite: "Pencil"
        default: title
        }
    }

    var symbol: String {
        switch self {
        case .ink: "pencil.and.outline"
        case .graphite: "pencil.line"
        case .crayon: "scribble"
        case .watercolor: "drop.fill"
        case .marker: "highlighter"
        case .paperCutout: "doc.on.doc.fill"
        case .clay: "circle.hexagongrid.fill"
        case .storybook: "book.pages.fill"
        }
    }

    var promptDescription: String {
        switch self {
        case .ink: "bold black ink on warm textured paper, crisp contours and playful hatching"
        case .graphite: "graphite pencil on visible sketch paper, construction lines and soft shading"
        case .crayon: "joyful wax crayon on toothy paper, uneven pressure and bright childlike colour"
        case .watercolor: "loose translucent watercolor on cold-press paper, pigment blooms and soft edges"
        case .marker: "juicy marker illustration on white paper, broad overlapping strokes and saturated colour"
        case .paperCutout: "layered handmade paper cutout collage, torn edges, fibres and tiny cast shadows"
        case .clay: "tactile handmade clay animation miniature with fingerprints and soft cinematic lighting"
        case .storybook: "lush hand-painted children's storybook illustration with warm magical light"
        }
    }
}

enum SketchFidelity: String, CaseIterable, Codable, Identifiable, Sendable {
    case faithful
    case balanced
    case creative

    var id: Self { self }
    var title: String { rawValue.capitalized }

    var summary: String {
        switch self {
        case .faithful: "Keep every wonderful wobble."
        case .balanced: "Keep the silhouette, polish the forms."
        case .creative: "Keep the idea, explore the world."
        }
    }

    var promptClause: String {
        switch self {
        case .faithful: "Preserve the exact silhouette, pose, proportions, feature count, and unusual line placement."
        case .balanced: "Preserve the composition and recognisable silhouette, while gently refining awkward forms."
        case .creative: "Keep the main subject clearly recognisable, but allow freer lighting, texture, and environmental interpretation."
        }
    }
}

enum CreativeOutput: String, CaseIterable, Codable, Identifiable, Sendable {
    case postcard
    case shortStory
    case animation
    case fullPack

    var id: Self { self }

    var title: String {
        switch self {
        case .postcard: "Fast illustrated postcard"
        case .shortStory: "Short story"
        case .animation: "Animated movie"
        case .fullPack: "Full adventure pack"
        }
    }

    var shortTitle: String {
        switch self {
        case .postcard: "Postcard"
        case .shortStory: "Short story"
        case .animation: "Movie"
        case .fullPack: "Full pack"
        }
    }

    var subtitle: String {
        switch self {
        case .postcard: "Fast image + funny identity"
        case .shortStory: "Illustration, tale + voice"
        case .animation: "A quick 8-sec scene or 10–30 sec reel"
        case .fullPack: "Image, story, voice + movie"
        }
    }

    var symbol: String {
        switch self {
        case .postcard: "photo.fill"
        case .shortStory: "book.fill"
        case .animation: "film.fill"
        case .fullPack: "sparkles.rectangle.stack.fill"
        }
    }

    var includesVideo: Bool { self == .animation || self == .fullPack }
    var includesLongStory: Bool { self == .shortStory || self == .fullPack }
}

enum VideoLength: Int, CaseIterable, Codable, Identifiable, Sendable {
    case quick = 8
    case ten = 10
    case twenty = 20
    case thirty = 30

    var id: Self { self }
    var title: String { self == .quick ? "Quick 8 sec" : "\(rawValue) sec" }
    var sceneCount: Int { Int(ceil(Double(rawValue) / 8.0)) }
    var isQuick: Bool { self == .quick }
    var sceneLabel: String { "\(sceneCount) \(sceneCount == 1 ? "scene" : "scenes")" }

    var waitHint: String {
        switch self {
        case .quick: "1 generated scene · fastest demo option"
        case .ten: "2 generated scenes · short montage"
        case .twenty: "3 generated scenes"
        case .thirty: "4 generated scenes · longest wait"
        }
    }
}

enum StoryLength: String, CaseIterable, Codable, Identifiable, Sendable {
    case short
    case medium
    case long

    var id: Self { self }
    var title: String { rawValue.capitalized }

    var subtitle: String {
        switch self {
        case .short: "A quick origin · about 60 words"
        case .medium: "A complete little tale · about 160 words"
        case .long: "A rich read-aloud chapter · about 320 words"
        }
    }

    var promptRule: String {
        switch self {
        case .short:
            "Write 45–70 words in 2–4 vivid sentences with a clear setup, funny turn, and warm ending."
        case .medium:
            "Write 130–180 words with a beginning, escalating problem, character choice, funny payoff, and warm ending."
        case .long:
            "Write 280–360 words as a polished read-aloud chapter with a beginning, three escalating beats, a character choice, a surprising payoff, and a satisfying warm ending."
        }
    }
}

struct ContinuationIdentity: Codable, Equatable, Sendable {
    let name: String
    let species: String
    let visibleTraits: [String]
    let personality: String
    let home: String
    let favoriteFood: String
    let fear: String

    init(profile: MonsterProfile) {
        name = profile.name
        species = profile.species
        visibleTraits = profile.visibleTraits
        personality = profile.personality
        home = profile.home
        favoriteFood = profile.favoriteFood
        fear = profile.fear
    }

    var promptSummary: String {
        "\(name) · \(species) · traits: \(visibleTraits.joined(separator: ", ")) · personality: \(personality) · home: \(home) · food: \(favoriteFood) · fear: \(fear)"
    }
}

struct CreativeBrief: Codable, Equatable, Sendable {
    var medium: CreativeMedium = .crayon
    var fidelity: SketchFidelity = .faithful
    var output: CreativeOutput = .postcard
    var storyLength: StoryLength = .short
    var storyDirection = ""
    var videoLength: VideoLength = .quick
    var sceneDirection = ""
    var usesSurpriseScenes = true
    var continuationContext: String?
    var continuationIdentity: ContinuationIdentity?

    static let demo = CreativeBrief()

    var promptContext: String {
        let scene = sceneDirection.trimmingCharacters(in: .whitespacesAndNewlines)
        let story = storyDirection.trimmingCharacters(in: .whitespacesAndNewlines)
        let continuation = continuationContext?.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        CREATIVE DIRECTION
        Physical medium: \(medium.title) — \(medium.promptDescription)
        Sketch fidelity: \(fidelity.title) — \(fidelity.promptClause)
        Requested output: \(output.title)
        Story length: \(storyLength.title) — \(storyLength.promptRule)
        Child's optional background/story idea: \(story.isEmpty ? "none; invent from the source idea" : String(story.prefix(600)))
        Movie length: \(videoLength.rawValue) seconds, assembled from \(videoLength.sceneCount) coherent scenes
        Scene direction: \(scene.isEmpty ? "Invent a playful visual surprise based on the character's personality." : String(scene.prefix(400)))
        Surprise mode: \(usesSurpriseScenes ? "invent extra funny visual beats" : "follow the child's direction closely")
        Continuation context: \(continuation.flatMap { $0.isEmpty ? nil : String($0.prefix(900)) } ?? "none; this is a new creation")
        Identity that must remain exact: \(continuationIdentity?.promptSummary ?? "none")
        """
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case medium
        case fidelity
        case output
        case storyLength
        case storyDirection
        case videoLength
        case sceneDirection
        case usesSurpriseScenes
        case continuationContext
        case continuationIdentity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        medium = try container.decodeIfPresent(CreativeMedium.self, forKey: .medium) ?? .crayon
        fidelity = try container.decodeIfPresent(SketchFidelity.self, forKey: .fidelity) ?? .faithful
        output = try container.decodeIfPresent(CreativeOutput.self, forKey: .output) ?? .postcard
        storyLength = try container.decodeIfPresent(StoryLength.self, forKey: .storyLength) ?? .short
        storyDirection = try container.decodeIfPresent(String.self, forKey: .storyDirection) ?? ""
        videoLength = try container.decodeIfPresent(VideoLength.self, forKey: .videoLength) ?? .quick
        sceneDirection = try container.decodeIfPresent(String.self, forKey: .sceneDirection) ?? ""
        usesSurpriseScenes = try container.decodeIfPresent(Bool.self, forKey: .usesSurpriseScenes) ?? true
        continuationContext = try container.decodeIfPresent(String.self, forKey: .continuationContext)
        continuationIdentity = try container.decodeIfPresent(ContinuationIdentity.self, forKey: .continuationIdentity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(medium, forKey: .medium)
        try container.encode(fidelity, forKey: .fidelity)
        try container.encode(output, forKey: .output)
        try container.encode(storyLength, forKey: .storyLength)
        try container.encode(storyDirection, forKey: .storyDirection)
        try container.encode(videoLength, forKey: .videoLength)
        try container.encode(sceneDirection, forKey: .sceneDirection)
        try container.encode(usesSurpriseScenes, forKey: .usesSurpriseScenes)
        try container.encodeIfPresent(continuationContext, forKey: .continuationContext)
        try container.encodeIfPresent(continuationIdentity, forKey: .continuationIdentity)
    }
}

enum SceneIdeas {
    static let suggestions = [
        "The character tries to catch a hiccup that glows like a tiny star, then celebrates with a proud wobble.",
        "A snack rolls away. The character chases it, discovers it can bounce, and lands in a silly hero pose.",
        "The character sneezes a cloud of harmless confetti, blinks in surprise, then dances through it.",
        "A shy moonbeam taps the character on the shoulder. They play hide-and-seek behind colourful shapes.",
        "The character discovers its shadow has its own dance moves and tries very hard to copy them.",
        "A tiny paper boat floats past. The character hops aboard and steers through a puddle-sized ocean.",
    ]

    static func random(excluding current: String = "") -> String {
        suggestions.filter { $0 != current }.randomElement() ?? suggestions[0]
    }
}
