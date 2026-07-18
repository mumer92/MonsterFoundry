import Foundation

public struct MonsterProfile: Codable, Equatable, Sendable {
    public let name: String
    public let species: String
    public let visibleTraits: [String]
    public let personality: String
    public let home: String
    public let favoriteFood: String
    public let fear: String
    public let backstory: String
    public let greeting: String
    public let firstAction: String
    public let imagePrompt: String
    public let motionPrompt: String
    public let scenePrompts: [String]
}

struct VideoStatusResponse: Decodable, Sendable {
    let status: String
    let videoPath: String?
    let message: String?
}

struct MonsterResult: Identifiable, Sendable {
    let id: UUID
    let createdAt: Date
    let profile: MonsterProfile
    let seed: CreativeSeed
    let heroImageData: Data?
    let heroImageMimeType: String
    let isFallback: Bool
    let brief: CreativeBrief

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        profile: MonsterProfile,
        seed: CreativeSeed,
        heroImageData: Data?,
        heroImageMimeType: String,
        isFallback: Bool,
        brief: CreativeBrief
    ) {
        self.id = id
        self.createdAt = createdAt
        self.profile = profile
        self.seed = seed
        self.heroImageData = heroImageData
        self.heroImageMimeType = heroImageMimeType
        self.isFallback = isFallback
        self.brief = brief
    }
}

enum VideoGenerationState: Equatable, Sendable {
    case idle
    case requesting(scene: Int, total: Int)
    case processing(scene: Int, total: Int)
    case ready(URL)
    case failed(String)
}

struct GenerationJob: Identifiable, Sendable {
    let id = UUID()
    let seed: CreativeSeed
    let brief: CreativeBrief
}

enum ExperiencePhase: Equatable {
    case drawing
    case customizing
    case awakening
    case reveal
    case gallery
}

extension MonsterProfile {
    func preservingIdentity(_ identity: ContinuationIdentity) -> MonsterProfile {
        MonsterProfile(
            name: identity.name,
            species: identity.species,
            visibleTraits: identity.visibleTraits,
            personality: identity.personality,
            home: identity.home,
            favoriteFood: identity.favoriteFood,
            fear: identity.fear,
            backstory: backstory,
            greeting: greeting,
            firstAction: firstAction,
            imagePrompt: imagePrompt,
            motionPrompt: motionPrompt,
            scenePrompts: scenePrompts
        )
    }

    static func fallback(for medium: CreativeMedium) -> MonsterProfile {
        let home: String
        switch medium {
        case .clay: home = "a warm teacup cave beneath the kitchen table"
        case .paperCutout: home = "between two folded paper mountains"
        case .storybook: home = "the unfinished page of a very ticklish book"
        case .watercolor: home = "a puddle that changes colour every Tuesday"
        default: home = "the secret margin of a child's favourite sketchbook"
        }

        return MonsterProfile(
            name: "Wobbleton Blink",
            species: "Rare Scribble Sprout",
            visibleTraits: ["brave outline", "mystery-shaped body", "excellent wobble"],
            personality: "Curious, kind, and dramatically surprised by socks.",
            home: home,
            favoriteFood: "crunchy Wi-Fi signals",
            fear: "charging cables pretending to be snakes",
            backstory: "Wobbleton tumbled out of a very important doodle and decided the world needed more odd shapes. Now every wobble leaves behind one tiny spark of courage.",
            greeting: "Hello! I am Wobbleton Blink. I eat Wi-Fi signals, but only the stale ones!",
            firstAction: "A delighted hop followed by a proud little wobble.",
            imagePrompt: "A playful world built around the creature's shapes.",
            motionPrompt: "The creature blinks, hops once, lands softly, then gives a proud little wobble.",
            scenePrompts: [
                "The creature blinks awake and gives one delighted hop.",
                "A glowing hiccup escapes and the creature tries to catch it.",
                "The creature discovers its shadow can dance.",
                "The creature lands in a proud pose and waves goodbye.",
            ]
        )
    }
}
