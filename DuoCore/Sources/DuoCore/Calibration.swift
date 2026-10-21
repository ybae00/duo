import Foundation

public struct PlayableRange: Sendable, Equatable {
    public let low: Double
    public let high: Double

    public init?(low: Double, high: Double) {
        guard low.isFinite, high.isFinite, low < high else { return nil }
        self.low = low
        self.high = high
    }
}

public enum CalibrationFailure: Error, Sendable, Equatable {
    case noReadings
    case noOpeningReading
    case rangeTooNarrow
}

public struct Calibration: Sendable {
    public static let minimumPlayableSpan: Double = 40

    public enum Phase: Sendable {
        case closing
        case opening
    }

    public private(set) var phase: Phase = .closing
    public private(set) var closedAngle: Double?
    public private(set) var fullyOpenAngle: Double?
    public private(set) var lowestSeen: Double?
    public private(set) var highestSeen: Double?
    private var highestOpeningReading: Double?

    public init() {}

    public mutating func beginOpening() {
        phase = .opening
    }

    public mutating func ingest(_ reading: HingeReading) {
        guard reading.degrees.isFinite, reading.time.isFinite, reading.pose != .unknown else { return }
        lowestSeen = min(lowestSeen ?? reading.degrees, reading.degrees)
        highestSeen = max(highestSeen ?? reading.degrees, reading.degrees)
        if phase == .opening {
            highestOpeningReading = max(highestOpeningReading ?? reading.degrees, reading.degrees)
        }
        if reading.pose == .closed {
            closedAngle = min(closedAngle ?? reading.degrees, reading.degrees)
        }
        if reading.pose == .open {
            fullyOpenAngle = max(fullyOpenAngle ?? reading.degrees, reading.degrees)
        }
    }

    public func finish(tuning: Tuning) -> Result<PlayableRange, CalibrationFailure> {
        finish(endMargin: tuning.endMargin, minimumPlayableSpan: tuning.minimumPlayableSpan)
    }

    public func finish(
        endMargin: Double = 8,
        minimumPlayableSpan: Double = Calibration.minimumPlayableSpan
    ) -> Result<PlayableRange, CalibrationFailure> {
        guard let lowestSeen else { return .failure(.noReadings) }
        guard let highestOpeningReading else { return .failure(.noOpeningReading) }
        let low = lowestSeen + endMargin
        let high = highestOpeningReading - endMargin
        guard endMargin.isFinite, endMargin >= 0, minimumPlayableSpan.isFinite, minimumPlayableSpan > 0,
            let range = PlayableRange(low: low, high: high), high - low >= minimumPlayableSpan
        else {
            return .failure(.rangeTooNarrow)
        }
        return .success(range)
    }
}
