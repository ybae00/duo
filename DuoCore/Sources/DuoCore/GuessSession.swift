import Foundation

public struct GuessResult: Equatable, Sendable {
    public let target: Int
    public let actual: Double

    public var error: Double { abs(actual - Double(target)) }

    public var percentageOff: Double? {
        guard target != 0 else { return error == 0 ? 0 : nil }
        let percentage = error / abs(Double(target)) * 100
        return percentage.isFinite ? percentage : nil
    }

    public var percentageCloseness: Double? {
        guard target != 0 else { return error == 0 ? 100 : nil }
        let relativeError = error / abs(Double(target))
        return (1 - min(relativeError, 1)) * 100
    }

    public init?(target: Int, actual: Double) {
        guard actual.isFinite, abs(actual - Double(target)).isFinite else { return nil }
        self.target = target
        self.actual = actual
    }
}

public struct GuessSession: Sendable {
    public enum State: Equatable, Sendable {
        case ready
        case guessing(target: Int)
        case result(GuessResult)
    }

    public let range: PlayableRange
    public private(set) var state: State = .ready
    public private(set) var reading: HingeReading?

    public init(range: PlayableRange) {
        self.range = range
    }

    public mutating func ingest(_ reading: HingeReading?) {
        guard let reading, reading.degrees.isFinite, reading.time.isFinite, reading.pose != .unknown else {
            self.reading = nil
            return
        }
        self.reading = reading
    }

    @discardableResult
    public mutating func start<R: RandomNumberGenerator>(using generator: inout R) -> Bool {
        if case .guessing = state { return false }
        guard let target = TargetPicker.pick(in: range, using: &generator) else { return false }
        state = .guessing(target: target)
        return true
    }

    @discardableResult
    public mutating func submit() -> Bool {
        guard case .guessing(let target) = state, let reading,
            let result = GuessResult(target: target, actual: reading.degrees)
        else { return false }
        state = .result(result)
        return true
    }
}
