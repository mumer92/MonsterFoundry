import AVFoundation
import Foundation

enum VideoComposerError: LocalizedError {
    case noVideoTrack
    case exportUnavailable

    var errorDescription: String? {
        switch self {
        case .noVideoTrack: "A generated scene did not contain playable video."
        case .exportUnavailable: "The character scenes could not be joined into a movie."
        }
    }
}

enum VideoComposer {
    static func compose(clips: [URL], targetDurationSeconds: Int) async throws -> URL {
        let composition = AVMutableComposition()
        guard let compositionVideo = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoComposerError.noVideoTrack
        }
        let compositionAudio = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        let targetDuration = CMTime(seconds: Double(targetDurationSeconds), preferredTimescale: 600)
        var cursor = CMTime.zero
        var appliedTransform = false

        for clipURL in clips where cursor < targetDuration {
            let asset = AVURLAsset(url: clipURL)
            let assetDuration = try await asset.load(.duration)
            let remaining = CMTimeSubtract(targetDuration, cursor)
            let insertDuration = CMTimeMinimum(assetDuration, remaining)
            guard insertDuration > .zero,
                  let sourceVideo = try await asset.loadTracks(withMediaType: .video).first else {
                continue
            }

            let timeRange = CMTimeRange(start: .zero, duration: insertDuration)
            try compositionVideo.insertTimeRange(timeRange, of: sourceVideo, at: cursor)

            if !appliedTransform {
                compositionVideo.preferredTransform = try await sourceVideo.load(.preferredTransform)
                appliedTransform = true
            }

            if let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first {
                try? compositionAudio?.insertTimeRange(timeRange, of: sourceAudio, at: cursor)
            }
            cursor = CMTimeAdd(cursor, insertDuration)
        }

        guard cursor > .zero else { throw VideoComposerError.noVideoTrack }
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoComposerError.exportUnavailable
        }

        let destination = FileManager.default.temporaryDirectory
            .appending(path: "monster-reel-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        try await exporter.export(to: destination, as: .mp4)
        return destination
    }
}
