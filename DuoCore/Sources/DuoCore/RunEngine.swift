import Foundation

public struct RoundResult: Codable, Equatable, Sendable {
    public let number: Int
    public let target: Int
    public let error: Double?
    public let elapsed: TimeInterval
    public let score: Int
}

public struct RunEngine: Sendable {
    public static let roundCount = 5

    public private(set) var results: [RoundResult] = []
    public private(set) var target: Int?
    public private(set) var judge: MatchJudge?
    public var isComplete: Bool { results.count == Self.roundCount }
    public var totalScore: Int { results.reduce(0) { $0 + $1.score } }
    public var roundNumber: Int { results.count + (target == nil ? 0 : 1) }

    private let range: PlayableRange
    private let tuning: Tuning

    public init(range: PlayableRange, tuning: Tuning) {
        self.range = range
        self.tuning = tuning
    }

    @discardableResult
    public mutating func startNext<R: RandomNumberGenerator>(
        current: HingeReading, now: TimeInterval, using generator: inout R
    ) -> Bool {
        guard !isComplete, target == nil, current.pose != .unknown,
            current.degrees.isFinite, current.time.isFinite, now.isFinite,
            current.time <= now, now - current.time <= tuning.staleReadingLimit,
            let next = TargetPicker.pick(
                in: range, previous: results.last?.target,
                currentDegrees: current.degrees, tuning: tuning, using: &generator
            )
        else { return false }
        target = next
        judge = MatchJudge(target: Double(next), tuning: tuning, startedAt: now)
        return true
    }

    @discardableResult
    public mutating func ingest(_ reading: HingeReading?) -> RoundResult? {
        guard judge != nil else { return nil }
        judge?.ingest(reading)
        return finishIfNeeded()
    }

    @discardableResult
    public mutating func tick(now: TimeInterval) -> RoundResult? {
        guard judge != nil else { return nil }
        judge?.tick(now: now)
        return finishIfNeeded()
    }

    public mutating func suspend(at now: TimeInterval) {
        judge?.suspend(at: now)
    }

    public mutating func resume(at now: TimeInterval) {
        judge?.resume(at: now)
    }

    private mutating func finishIfNeeded() -> RoundResult? {
        guard let target, let judge else { return nil }
        let result: RoundResult
        switch judge.state {
        case .matched(let error, let elapsed):
            result = RoundResult(
                number: results.count + 1, target: target, error: error,
                elapsed: elapsed, score: Scoring.points(error: error, elapsed: elapsed, tuning: tuning)
            )
        case .timedOut:
            result = RoundResult(
                number: results.count + 1, target: target, error: nil,
                elapsed: tuning.roundTimeLimit, score: 0
            )
        case .searching, .holding:
            return nil
        }
        results.append(result)
        self.target = nil
        self.judge = nil
        return result
    }
}
