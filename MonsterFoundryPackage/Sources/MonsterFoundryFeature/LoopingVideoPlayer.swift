import AVFoundation
import AVKit
import SwiftUI

struct LoopingVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspectFill
        context.coordinator.load(url: url, into: controller)
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.load(url: url, into: controller)
    }

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.stop()
        controller.player = nil
    }

    @MainActor
    final class Coordinator {
        private var queuePlayer: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        var currentURL: URL?

        func load(url: URL, into controller: AVPlayerViewController) {
            stop()
            currentURL = url
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            queuePlayer = player
            looper = AVPlayerLooper(player: player, templateItem: item)
            controller.player = player
            player.play()
        }

        func stop() {
            queuePlayer?.pause()
            looper?.disableLooping()
            looper = nil
            queuePlayer = nil
            currentURL = nil
        }
    }
}
