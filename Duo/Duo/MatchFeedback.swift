import AVFAudio
import Foundation
import UIKit

@MainActor
final class MatchFeedback {
    private var player: AVAudioPlayer?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        if let url = Bundle.main.url(forResource: "match", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }
    }

    func success(haptics: Bool, sound: Bool) {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        if sound {
            player?.currentTime = 0
            player?.play()
        }
    }

    func timeout(haptics: Bool) {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    }
}
