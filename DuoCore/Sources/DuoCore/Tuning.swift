import Foundation

public struct Tuning: Sendable, Equatable {
    public let tolerance: Double
    public let holdTime: TimeInterval
    public let endMargin: Double
    public let minimumTargetDistance: Double
    public let minimumPlayableSpan: Double
    public let roundTimeLimit: TimeInterval
    public let staleReadingLimit: TimeInterval

    public init(
        tolerance: Double,
        holdTime: TimeInterval,
        endMargin: Double,
        minimumTargetDistance: Double,
        minimumPlayableSpan: Double,
        roundTimeLimit: TimeInterval,
        staleReadingLimit: TimeInterval
    ) {
        precondition(tolerance.isFinite && tolerance > 0)
        precondition(holdTime.isFinite && holdTime > 0)
        precondition(endMargin.isFinite && endMargin >= 0)
        precondition(minimumTargetDistance.isFinite && minimumTargetDistance > 0)
        precondition(minimumPlayableSpan.isFinite && minimumPlayableSpan > 0)
        precondition(roundTimeLimit.isFinite && roundTimeLimit > holdTime)
        precondition(staleReadingLimit.isFinite && staleReadingLimit >= holdTime)
        self.tolerance = tolerance
        self.holdTime = holdTime
        self.endMargin = endMargin
        self.minimumTargetDistance = minimumTargetDistance
        self.minimumPlayableSpan = minimumPlayableSpan
        self.roundTimeLimit = roundTimeLimit
        self.staleReadingLimit = staleReadingLimit
    }

    public static let easy = Tuning(
        tolerance: 6, holdTime: 0.7, endMargin: 8, minimumTargetDistance: 18,
        minimumPlayableSpan: 40, roundTimeLimit: 15, staleReadingLimit: 30
    )
    public static let normal = Tuning(
        tolerance: 4, holdTime: 1, endMargin: 8, minimumTargetDistance: 18,
        minimumPlayableSpan: 40, roundTimeLimit: 15, staleReadingLimit: 30
    )
    public static let hard = Tuning(
        tolerance: 2, holdTime: 1.5, endMargin: 8, minimumTargetDistance: 18,
        minimumPlayableSpan: 40, roundTimeLimit: 15, staleReadingLimit: 30
    )
}
