import Foundation

struct OpenAINarrationClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateStoryAudio(text: String, voice: String = "marin") async throws -> Data {
        guard let apiKey = APIKeyStore.value(for: "openai_api_key") else {
            throw OpenAINarrationError.missingKey
        }
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            throw OpenAINarrationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            SpeechRequest(
                model: "gpt-4o-mini-tts",
                voice: voice,
                input: String(text.prefix(4_000)),
                instructions: "Read as a warm, playful children's storyteller. Use expressive but gentle pacing, clear character emotion, and a cosy ending. Never sound frightening or imitate a real person.",
                responseFormat: "mp3"
            )
        )

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw OpenAINarrationError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode), data.count > 1_000 else {
                throw OpenAINarrationError.server(http.statusCode)
            }
            return data
        } catch let error as OpenAINarrationError {
            throw error
        } catch {
            throw OpenAINarrationError.connection
        }
    }
}

private struct SpeechRequest: Encodable {
    let model: String
    let voice: String
    let input: String
    let instructions: String
    let responseFormat: String

    private enum CodingKeys: String, CodingKey {
        case model
        case voice
        case input
        case instructions
        case responseFormat = "response_format"
    }
}

enum OpenAINarrationError: LocalizedError {
    case missingKey
    case connection
    case invalidResponse
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .missingKey: "The OpenAI voice key is not configured."
        case .connection: "The AI narrator could not be reached."
        case .invalidResponse: "The AI narrator returned unreadable audio."
        case .server(let status): "The AI narrator returned error \(status)."
        }
    }
}
