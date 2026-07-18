import Foundation

struct MonsterAPIClient: Sendable {
    private static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
    private static let storyModel = "gemini-3.1-flash-lite"
    private static let imageModel = "gemini-3.1-flash-lite-image"
    private static let videoModel = "veo-3.1-lite-generate-preview"

    private let apiKeyOverride: String?
    private let session: URLSession

    init(apiKey: String? = nil, session: URLSession = .shared) {
        apiKeyOverride = apiKey
        self.session = session
    }

    func awaken(
        seed: CreativeSeed,
        brief: CreativeBrief
    ) async throws -> MonsterResult {
        guard seed.hasContent else { throw MonsterAPIError.invalidResponse }
        let apiKey = try resolvedAPIKey()
        let profile = try await generateProfile(
            seed: seed,
            brief: brief,
            apiKey: apiKey
        )
        let hero = try await generateImage(
            seed: seed,
            profile: profile,
            brief: brief,
            apiKey: apiKey
        )

        return MonsterResult(
            profile: profile,
            seed: seed,
            heroImageData: hero.data,
            heroImageMimeType: hero.mimeType,
            isFallback: false,
            brief: brief
        )
    }

    func beginAnimation(for result: MonsterResult, scenePrompt: String) async throws -> String {
        guard let imageData = result.heroImageData else { throw MonsterAPIError.invalidResponse }
        let apiKey = try resolvedAPIKey()
        let url = try endpoint("models/\(Self.videoModel):predictLongRunning")
        let body: JSONValue = .object([
            "instances": .array([
                .object([
                    "prompt": .string(videoPrompt(scenePrompt, result: result)),
                    "image": .object([
                        "bytesBase64Encoded": .string(imageData.base64EncodedString()),
                        "mimeType": .string(result.heroImageMimeType),
                    ]),
                ]),
            ]),
            "parameters": .object([
                "aspectRatio": .string("16:9"),
                "durationSeconds": .number(8),
                "resolution": .string("720p"),
                "sampleCount": .number(1),
            ]),
        ])

        let response = try await postJSON(url: url, body: body, apiKey: apiKey, timeout: 150)
        guard let operation = response["name"]?.stringValue,
              operation.hasPrefix("models/\(Self.videoModel)/operations/") else {
            throw MonsterAPIError.invalidResponse
        }
        return operation
    }

    func animationStatus(operation: String) async throws -> VideoStatusResponse {
        let apiKey = try resolvedAPIKey()
        let response = try await getJSON(
            url: try endpoint(operation),
            apiKey: apiKey,
            timeout: 30
        )

        if let message = response["error"]?["message"]?.stringValue {
            return VideoStatusResponse(status: "failed", videoPath: nil, message: message)
        }
        guard response["done"]?.boolValue == true else {
            return VideoStatusResponse(status: "processing", videoPath: nil, message: nil)
        }
        guard let remoteURL = extractVideoURL(from: response) else {
            return VideoStatusResponse(
                status: "failed",
                videoPath: nil,
                message: "The animation finished without a playable movie."
            )
        }

        let localURL = try await downloadVideo(from: remoteURL, apiKey: apiKey)
        return VideoStatusResponse(status: "complete", videoPath: localURL.absoluteString, message: nil)
    }

    func videoURL(path: String) -> URL? {
        URL(string: path)
    }

    private func generateProfile(
        seed: CreativeSeed,
        brief: CreativeBrief,
        apiKey: String
    ) async throws -> MonsterProfile {
        var input: [JSONValue] = []
        if let sketchData = seed.sketchData {
            input.append(.object([
                "type": .string("image"),
                "data": .string(sketchData.base64EncodedString()),
                "mime_type": .string("image/jpeg"),
            ]))
        }
        input.append(.object([
            "type": .string("text"),
            "text": .string(storyPrompt(seed: seed, brief: brief)),
        ]))

        let body: JSONValue = .object([
            "model": .string(Self.storyModel),
            "input": .array(input),
            "response_format": .object([
                "type": .string("text"),
                "mime_type": .string("application/json"),
                "schema": monsterProfileSchema,
            ]),
        ])

        let response = try await postJSON(
            url: try endpoint("interactions"),
            body: body,
            apiKey: apiKey,
            timeout: 120
        )
        guard let outputText = extractOutputText(from: response),
              let data = outputText.data(using: .utf8),
              let profile = try? JSONDecoder().decode(MonsterProfile.self, from: data) else {
            throw MonsterAPIError.invalidResponse
        }
        guard let identity = brief.continuationIdentity else { return profile }
        return profile.preservingIdentity(identity)
    }

    private func generateImage(
        seed: CreativeSeed,
        profile: MonsterProfile,
        brief: CreativeBrief,
        apiKey: String
    ) async throws -> (data: Data, mimeType: String) {
        var input: [JSONValue] = []
        if let sketchData = seed.sketchData {
            input.append(.object([
                "type": .string("image"),
                "data": .string(sketchData.base64EncodedString()),
                "mime_type": .string("image/jpeg"),
            ]))
        }
        input.append(.object([
            "type": .string("text"),
            "text": .string(imagePrompt(profile, seed: seed, brief: brief)),
        ]))

        let body: JSONValue = .object([
            "model": .string(Self.imageModel),
            "input": .array(input),
            "response_format": .object([
                "type": .string("image"),
                "mime_type": .string("image/jpeg"),
                "aspect_ratio": .string("16:9"),
                "image_size": .string("1K"),
            ]),
        ])

        let response = try await postJSON(
            url: try endpoint("interactions"),
            body: body,
            apiKey: apiKey,
            timeout: 150
        )
        guard let image = extractOutputImage(from: response),
              let data = Data(base64Encoded: image.data) else {
            throw MonsterAPIError.invalidResponse
        }
        return (data, image.mimeType)
    }

    private func postJSON(
        url: URL,
        body: JSONValue,
        apiKey: String,
        timeout: TimeInterval
    ) async throws -> JSONValue {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(body)
        return try await performJSON(request)
    }

    private func getJSON(url: URL, apiKey: String, timeout: TimeInterval) async throws -> JSONValue {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        return try await performJSON(request)
    }

    private func performJSON(_ request: URLRequest) async throws -> JSONValue {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw MonsterAPIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else {
                let payload = try? JSONDecoder().decode(JSONValue.self, from: data)
                let message = payload?["error"]?["message"]?.stringValue
                throw MonsterAPIError.server(message ?? "Gemini returned error \(http.statusCode).")
            }
            return try JSONDecoder().decode(JSONValue.self, from: data)
        } catch let error as MonsterAPIError {
            throw error
        } catch is DecodingError {
            throw MonsterAPIError.invalidResponse
        } catch {
            throw MonsterAPIError.connection
        }
    }

    private func downloadVideo(from remoteURL: URL, apiKey: String) async throws -> URL {
        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 120
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        do {
            let (temporaryURL, response) = try await session.download(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw MonsterAPIError.server("The generated movie could not be downloaded.")
            }

            let destination = FileManager.default.temporaryDirectory
                .appending(path: "monster-\(UUID().uuidString)")
                .appendingPathExtension("mp4")
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            return destination
        } catch let error as MonsterAPIError {
            throw error
        } catch {
            throw MonsterAPIError.connection
        }
    }

    private func resolvedAPIKey() throws -> String {
        if let apiKeyOverride, !apiKeyOverride.isEmpty { return apiKeyOverride }
        guard let key = APIKeyStore.value(for: "gemini_api_key") else {
            throw MonsterAPIError.missingKey
        }
        return key
    }

    private func endpoint(_ path: String) throws -> URL {
        guard let url = URL(string: "\(Self.geminiBaseURL)/\(path)") else {
            throw MonsterAPIError.invalidResponse
        }
        return url
    }
}

enum MonsterAPIError: LocalizedError, Equatable {
    case missingKey
    case connection
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            "Add gemini_api_key to keys.plist and make sure the file belongs to the app target."
        case .connection:
            "Gemini could not be reached. Check the internet connection and try again."
        case .invalidResponse:
            "Gemini sent back something the app could not understand."
        case .server(let message):
            message
        }
    }
}

private indirect enum JSONValue: Codable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    subscript(key: String) -> JSONValue? {
        guard case .object(let value) = self else { return nil }
        return value[key]
    }

    var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    var arrayValue: [JSONValue]? {
        guard case .array(let value) = self else { return nil }
        return value
    }
}

private func extractOutputText(from response: JSONValue) -> String? {
    if let direct = response["output_text"]?.stringValue ?? response["outputText"]?.stringValue {
        return direct
    }
    return interactionContentBlocks(response).first { $0["type"]?.stringValue == "text" }?["text"]?.stringValue
}

private func extractOutputImage(from response: JSONValue) -> (data: String, mimeType: String)? {
    let direct = response["output_image"] ?? response["outputImage"]
    if let data = direct?["data"]?.stringValue {
        return (data, direct?["mime_type"]?.stringValue ?? "image/jpeg")
    }

    for block in interactionContentBlocks(response) where block["type"]?.stringValue == "image" {
        if let data = block["data"]?.stringValue {
            return (data, block["mime_type"]?.stringValue ?? "image/jpeg")
        }
    }
    return nil
}

private func interactionContentBlocks(_ response: JSONValue) -> [JSONValue] {
    guard let steps = response["steps"]?.arrayValue else { return [] }
    return steps.flatMap { $0["content"]?.arrayValue ?? [] }
}

private func extractVideoURL(from response: JSONValue) -> URL? {
    let samples = response["response"]?["generateVideoResponse"]?["generatedSamples"]?.arrayValue
    guard let uri = samples?.first?["video"]?["uri"]?.stringValue else { return nil }
    return URL(string: uri)
}

private func storyPrompt(seed: CreativeSeed, brief: CreativeBrief) -> String {
    """
    You are a warm, inventive children's character designer and story author. Discover the original character inside the child's sketch or written idea.

    Child's written idea: \(seed.promptDescription)
    \(seed.sketchData == nil ? "There is no sketch. Treat the written idea as the source of truth." : "Study the attached sketch carefully. Ground visibleTraits in 1 to 4 features genuinely visible in it, and preserve ambiguity where a mark is unclear.")

    The subject is not always a monster. It may be a creature, animal, person-like doodle, robot, object, vehicle, place mascot, or something uncategorisable. Follow the child's source instead of forcing it into a monster template. It must be friendly, original, surprising, funny, and appropriate for ages 6–12. Give it a memorable invented name, a concise imaginative type in species, a home related to its shapes, a silly food, and a harmless fear. The greeting must be speakable in under 12 seconds. The first action is one simple animation beat.

    The backstory must obey the selected story-length rule exactly. It needs a real beginning, change or problem, character choice, and satisfying funny or heartfelt ending—not a list of facts. Incorporate the child's optional background idea when provided. If this is a continuation, keep the existing name, design, personality, and facts exactly, then write the next chapter rather than restarting the origin.

    The imagePrompt describes a polished 16:9 hero scene in the selected physical art medium. The motionPrompt describes one simple first action. scenePrompts must contain exactly four distinct, visually connected eight-second scenes that form a tiny beginning-middle-end story. Each scene starts with the same character design, uses at most one simple action, and can be generated independently from the hero image. Follow the child's scene direction when supplied; otherwise invent playful surprises from the character's personality.

    Do not mention brands, copyrighted characters, violence, weapons, real people, or horror. Do not add dialogue to scene prompts.

    \(brief.promptContext)
    """
}

private func imagePrompt(
    _ profile: MonsterProfile,
    seed: CreativeSeed,
    brief: CreativeBrief
) -> String {
    return """
    \(seed.sketchData == nil ? "Create the child's written character idea" : "Transform the supplied child's sketch") into a polished hero character inside its own world.

    \(seed.sketchData == nil ? "Follow the written idea exactly and keep the design simple enough to redraw." : "Preserve the original silhouette, proportions, feature count, and every unusual mark. Imperfect details are intentional. The result must unmistakably be the child's subject, not a replacement.")

    Name: \(profile.name)
    Species: \(profile.species)
    Visible traits: \(profile.visibleTraits.joined(separator: ", "))
    Home: \(profile.home)
    Personality: \(profile.personality)
    Backstory: \(profile.backstory)
    Scene direction: \(profile.imagePrompt)
    Child's idea: \(seed.promptDescription)

    Creative choices:
    \(brief.promptContext)

    Highest-priority preservation: \(brief.fidelity.promptClause)
    Render using this selected physical medium: \(brief.medium.promptDescription).

    Child-friendly and expressive, with the complete main subject visible and centred in a cinematic 16:9 frame. The environment should tell the first instant of its story. No text labels, logos, watermarks, unrelated extra characters, accidental duplicate features, cropped subject, weapons, horror, or redesign.
    """
}

private func videoPrompt(_ scenePrompt: String, result: MonsterResult) -> String {
    """
    Scene action: \(scenePrompt)
    Character: \(result.profile.name), described as \(result.profile.species).
    Personality: \(result.profile.personality)
    Selected look: \(result.brief.medium.promptDescription).

    Animate only the supplied main subject and subtle environmental details. Preserve its exact appearance, art medium, colours, silhouette, feature count, face when present, proportions, and environment. One continuous 16:9 shot with gentle child-friendly motion. No redesign, no new characters, no text, no logos, no frightening action, and no scene cuts. Keep the action readable within eight seconds and settle into a clear ending pose.
    """
}

private let monsterProfileSchema: JSONValue = .object([
    "type": .string("object"),
    "additionalProperties": .bool(false),
    "required": .array([
        "name", "species", "visibleTraits", "personality", "home", "favoriteFood", "fear",
        "backstory", "greeting", "firstAction", "imagePrompt", "motionPrompt", "scenePrompts",
    ].map(JSONValue.string)),
    "properties": .object([
        "name": .object(["type": .string("string")]),
        "species": .object(["type": .string("string")]),
        "visibleTraits": .object([
            "type": .string("array"),
            "minItems": .number(1),
            "maxItems": .number(4),
            "items": .object(["type": .string("string")]),
        ]),
        "personality": .object(["type": .string("string")]),
        "home": .object(["type": .string("string")]),
        "favoriteFood": .object(["type": .string("string")]),
        "fear": .object(["type": .string("string")]),
        "backstory": .object(["type": .string("string")]),
        "greeting": .object(["type": .string("string")]),
        "firstAction": .object(["type": .string("string")]),
        "imagePrompt": .object(["type": .string("string")]),
        "motionPrompt": .object(["type": .string("string")]),
        "scenePrompts": .object([
            "type": .string("array"),
            "minItems": .number(4),
            "maxItems": .number(4),
            "items": .object(["type": .string("string")]),
        ]),
    ]),
])
