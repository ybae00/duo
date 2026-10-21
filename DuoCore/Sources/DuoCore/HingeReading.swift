import Foundation

public enum Pose: Sendable, Equatable {
    case closed
    case partial
    case open
    case unknown
}

public struct HingeReading: Sendable, Equatable {
    public let degrees: Double
    public let pose: Pose
    public let time: TimeInterval

    public init(degrees: Double, pose: Pose, time: TimeInterval) {
        self.degrees = degrees
        self.pose = pose
        self.time = time
    }
}
