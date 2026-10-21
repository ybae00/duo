import Foundation

public enum Scoring {
    public static let maximumPoints = 1_000

    public static func points(error: Double, elapsed: TimeInterval, tuning: Tuning) -> Int {
        guard error.isFinite, elapsed.isFinite,
            error >= 0, error <= tuning.tolerance,
            elapsed >= 0, elapsed < tuning.roundTimeLimit
        else { return 0 }

        let accuracy = 1 - 0.5 * error / tuning.tolerance
        let speed = 1 - 0.5 * elapsed / tuning.roundTimeLimit
        return Int((Double(maximumPoints) * accuracy * speed).rounded(.down))
    }
}
