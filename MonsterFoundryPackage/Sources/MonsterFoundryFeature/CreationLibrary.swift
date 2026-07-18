import Foundation
import Observation

struct SavedCreation: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var profile: MonsterProfile
    var creaturePrompt: String
    var sketchFileName: String?
    var imageFileName: String?
    var heroImageMimeType: String
    var videoFileName: String?
    var narrationFileName: String?
    var isFallback: Bool
    var brief: CreativeBrief
    /// Optional so creations saved before favourites existed still decode
    /// (missing key → nil → treated as not favourited).
    var isFavorite: Bool?

    var isPinned: Bool { isFavorite == true }
}

@MainActor
@Observable
final class CreationLibrary {
    private(set) var creations: [SavedCreation] = []
    private(set) var lastError: String?

    private let fileManager: FileManager
    private let rootURL: URL
    private let indexURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootURL = support.appending(path: "MonsterFoundryLibrary", directoryHint: .isDirectory)
        indexURL = rootURL.appending(path: "creations.json")
        load()
    }

    @discardableResult
    func save(_ result: MonsterResult) -> SavedCreation? {
        do {
            try prepareDirectory()
            let existing = creations.first { $0.id == result.id }
            let sketchName = try write(result.seed.sketchData, name: "\(result.id.uuidString)-sketch.jpg")
                ?? existing?.sketchFileName
            let imageName = try write(result.heroImageData, name: "\(result.id.uuidString)-hero.jpg")
                ?? existing?.imageFileName

            let saved = SavedCreation(
                id: result.id,
                createdAt: result.createdAt,
                profile: result.profile,
                creaturePrompt: result.seed.creaturePrompt,
                sketchFileName: sketchName,
                imageFileName: imageName,
                heroImageMimeType: result.heroImageMimeType,
                videoFileName: existing?.videoFileName,
                narrationFileName: existing?.narrationFileName,
                isFallback: result.isFallback,
                brief: result.brief,
                isFavorite: existing?.isFavorite
            )
            replace(saved)
            try persistIndex()
            lastError = nil
            return saved
        } catch {
            lastError = "This creation could not be saved on this device."
            return nil
        }
    }

    func attachVideo(_ sourceURL: URL, to resultID: UUID) {
        guard let existing = creations.first(where: { $0.id == resultID }) else { return }
        do {
            try prepareDirectory()
            let name = "\(resultID.uuidString)-movie.mp4"
            let destination = rootURL.appending(path: name)
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            var updated = existing
            updated.videoFileName = name
            replace(updated)
            try persistIndex()
            lastError = nil
        } catch {
            lastError = "The movie played, but could not be added to My Creations."
        }
    }

    /// Toggles or sets the favourite flag on a saved creation and persists it.
    func setFavorite(_ isFavorite: Bool, for resultID: UUID) {
        guard var existing = creations.first(where: { $0.id == resultID }) else { return }
        existing.isFavorite = isFavorite
        replace(existing)
        try? persistIndex()
    }

    /// Everything that can be shared for a creation: the movie if present,
    /// otherwise the hero image written to a temporary file for the share sheet.
    func shareItems(for creation: SavedCreation) -> [URL] {
        var items: [URL] = []
        if let video = videoURL(for: creation) { items.append(video) }
        if items.isEmpty, let name = creation.imageFileName {
            let url = rootURL.appending(path: name)
            if fileManager.fileExists(atPath: url.path()) { items.append(url) }
        }
        if items.isEmpty, let name = creation.sketchFileName {
            let url = rootURL.appending(path: name)
            if fileManager.fileExists(atPath: url.path()) { items.append(url) }
        }
        return items
    }

    @discardableResult
    func attachNarration(_ sourceURL: URL, to resultID: UUID) -> URL? {
        guard let existing = creations.first(where: { $0.id == resultID }) else { return nil }
        do {
            try prepareDirectory()
            let name = "\(resultID.uuidString)-narration.mp3"
            let destination = rootURL.appending(path: name)
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            var updated = existing
            updated.narrationFileName = name
            replace(updated)
            try persistIndex()
            lastError = nil
            return destination
        } catch {
            lastError = "The story played, but its narration could not be saved."
            return nil
        }
    }

    func delete(_ creation: SavedCreation) {
        for name in [creation.sketchFileName, creation.imageFileName, creation.videoFileName, creation.narrationFileName].compactMap({ $0 }) {
            try? fileManager.removeItem(at: rootURL.appending(path: name))
        }
        creations.removeAll { $0.id == creation.id }
        try? persistIndex()
    }

    func result(for creation: SavedCreation) -> MonsterResult {
        let sketchData = data(named: creation.sketchFileName)
        let imageData = data(named: creation.imageFileName)
        return MonsterResult(
            id: creation.id,
            createdAt: creation.createdAt,
            profile: creation.profile,
            seed: CreativeSeed(sketchData: sketchData, creaturePrompt: creation.creaturePrompt),
            heroImageData: imageData,
            heroImageMimeType: creation.heroImageMimeType,
            isFallback: creation.isFallback,
            brief: creation.brief
        )
    }

    func videoURL(for creation: SavedCreation) -> URL? {
        guard let name = creation.videoFileName else { return nil }
        let url = rootURL.appending(path: name)
        return fileManager.fileExists(atPath: url.path()) ? url : nil
    }

    func narrationURL(for creation: SavedCreation) -> URL? {
        guard let name = creation.narrationFileName else { return nil }
        let url = rootURL.appending(path: name)
        return fileManager.fileExists(atPath: url.path()) ? url : nil
    }

    func imageData(for creation: SavedCreation) -> Data? {
        data(named: creation.imageFileName) ?? data(named: creation.sketchFileName)
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder.libraryDecoder.decode([SavedCreation].self, from: data) else {
            creations = []
            return
        }
        creations = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func replace(_ creation: SavedCreation) {
        creations.removeAll { $0.id == creation.id }
        creations.append(creation)
        creations.sort { $0.createdAt > $1.createdAt }
    }

    private func prepareDirectory() throws {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    private func write(_ data: Data?, name: String) throws -> String? {
        guard let data else { return nil }
        try data.write(to: rootURL.appending(path: name), options: .atomic)
        return name
    }

    private func data(named name: String?) -> Data? {
        guard let name else { return nil }
        return try? Data(contentsOf: rootURL.appending(path: name))
    }

    private func persistIndex() throws {
        let data = try JSONEncoder.libraryEncoder.encode(creations)
        try data.write(to: indexURL, options: .atomic)
    }
}

private extension JSONEncoder {
    static var libraryEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var libraryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
