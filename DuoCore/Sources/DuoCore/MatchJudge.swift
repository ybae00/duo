import Foundation

public enum MatchState: Equatable, Sendable {
    case searching
    case holding(since: TimeInterval)
    case matched(error: Double, time: TimeInterval)
    case timedOut
}

public struct MatchJudge: Sendable {
    public private(set) var state: MatchState = .searching
    public private(set) var latestReading: HingeReading?

    private let target: Double
    private let tuning: Tuning
    private var startedAt: TimeInterval
    private var lastEventTime: TimeInterval
    private var holdStartedAt: TimeInterval?
    private var suspendedAt: TimeInterval?

    public init(target: Double, tuning: Tuning, startedAt: TimeInterval) {
        precondition(target.isFinite && startedAt.isFinite)
        self.target = target
        self.tuning = tuning
        self.startedAt = startedAt
        lastEventTime = startedAt
    }

    public mutating func ingest(_ reading: HingeReading?) {
        guard !isFinished, suspendedAt == nil else { return }
        guard let reading else {
            latestReading = nil
            resetHold()
            return
        }
        guard reading.time.isFinite, reading.time >= lastEventTime else { return }
        lastEventTime = reading.time
        guard reading.degrees.isFinite else {
            latestReading = nil
            resetHold()
            return
        }
        latestReading = reading
        evaluate(at: reading.time)
    }

    public mutating func tick(now: TimeInterval) {
        guard !isFinished, suspendedAt == nil, now.isFinite, now >= lastEventTime else { return }
        lastEventTime = now
        evaluate(at: now)
    }

    public mutating func suspend(at now: TimeInterval) {
        guard !isFinished, suspendedAt == nil, now.isFinite, now >= lastEventTime else { return }
        suspendedAt = now
        latestReading = nil
        resetHold()
    }

    public mutating func resume(at now: TimeInterval) {
        guard let suspendedAt, now.isFinite, now >= suspendedAt else { return }
        startedAt += now - suspendedAt
        lastEventTime = now
        self.suspendedAt = nil
    }

    public func remainingTime(at now: TimeInterval) -> TimeInterval {
        let clock = suspendedAt ?? now
        guard clock.isFinite else { return tuning.roundTimeLimit }
        return max(0, tuning.roundTimeLimit - (clock - startedAt))
    }

    private var isFinished: Bool {
        switch state {
        case .matched, .timedOut: return true
        case .searching, .holding: return false
        }
    }

    private mutating func resetHold() {
        holdStartedAt = nil
        state = .searching
    }

    private mutating func evaluate(at now: TimeInterval) {
        if now - startedAt >= tuning.roundTimeLimit {
            holdStartedAt = nil
            state = .timedOut
            return
        }
        guard let reading = latestReading,
            reading.pose != .unknown,
            now - reading.time <= tuning.staleReadingLimit,
            abs(reading.degrees - target) <= tuning.tolerance
        else {
            resetHold()
            return
        }

        if holdStartedAt == nil {
            holdStartedAt = now
        }
        guard let since = holdStartedAt else { return }
        if now - since >= tuning.holdTime {
            state = .matched(error: abs(reading.degrees - target), time: now - startedAt)
        } else {
            state = .holding(since: since)
        }
    }
}
