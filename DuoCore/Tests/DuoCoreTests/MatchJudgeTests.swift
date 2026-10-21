import Testing

@testable import DuoCore

private func reading(_ degrees: Double, time: Double, pose: Pose = .partial) -> HingeReading {
    HingeReading(degrees: degrees, pose: pose, time: time)
}

@Test func stillReadingMatchesOnlyAfterTheHoldTime() {
    var judge = MatchJudge(target: 90, tuning: .normal, startedAt: 10)
    judge.ingest(reading(92, time: 10.2))
    #expect(judge.state == .holding(since: 10.2))
    judge.tick(now: 11.19)
    #expect(judge.state == .holding(since: 10.2))
    judge.tick(now: 11.2)
    if case .matched(let error, let time) = judge.state {
        #expect(error == 2)
        #expect(abs(time - 1.2) < 0.000_001)
    } else {
        Issue.record("Expected a match after the still hold")
    }
}

@Test func leavingTheWindowResetsTheEntireHold() {
    var judge = MatchJudge(target: 90, tuning: .normal, startedAt: 0)
    judge.ingest(reading(90, time: 0))
    judge.tick(now: 0.8)
    judge.ingest(reading(95, time: 0.9))
    #expect(judge.state == .searching)
    judge.ingest(reading(91, time: 1.0))
    judge.tick(now: 1.9)
    #expect(judge.state == .holding(since: 1))
    judge.tick(now: 2)
    #expect(judge.state == .matched(error: 1, time: 2))
}

@Test func unknownPoseAndUnavailableHingeCancelTheHold() {
    var judge = MatchJudge(target: 90, tuning: .normal, startedAt: 0)
    judge.ingest(reading(90, time: 0))
    judge.ingest(reading(90, time: 0.5, pose: .unknown))
    #expect(judge.state == .searching)
    judge.ingest(reading(90, time: 0.6))
    judge.ingest(nil)
    judge.tick(now: 1.6)
    #expect(judge.state == .searching)
    #expect(judge.latestReading == nil)
}

@Test func staleReadingsCannotCompleteAHold() {
    let tuning = Tuning(
        tolerance: 4, holdTime: 0.5, endMargin: 8,
        minimumTargetDistance: 18, minimumPlayableSpan: 40,
        roundTimeLimit: 15, staleReadingLimit: 1)
    var judge = MatchJudge(target: 90, tuning: tuning, startedAt: 0)
    judge.ingest(reading(90, time: 0))
    judge.tick(now: 1.1)
    #expect(judge.state == .searching)
    judge.ingest(reading(91, time: 1.2))
    judge.tick(now: 1.7)
    #expect(judge.state == .matched(error: 1, time: 1.7))
}

@Test func roundTimesOutAndCannotBeResurrected() {
    var judge = MatchJudge(target: 90, tuning: .normal, startedAt: 10)
    judge.ingest(reading(90, time: 24.9))
    judge.tick(now: 25)
    #expect(judge.state == .timedOut)
    judge.ingest(reading(90, time: 25.1))
    #expect(judge.state == .timedOut)
}

@Test func oldAndInvalidEventsCannotMoveTheJudgeBackward() {
    var judge = MatchJudge(target: 90, tuning: .normal, startedAt: 10)
    judge.ingest(reading(90, time: 10.3))
    judge.tick(now: 10.7)
    judge.ingest(reading(200, time: 10.5))
    judge.tick(now: 10.6)
    #expect(judge.state == .holding(since: 10.3))
    judge.ingest(reading(.nan, time: 10.8))
    #expect(judge.state == .searching)
    judge.tick(now: 11.3)
    #expect(judge.state == .searching)
}

@Test func boundaryAnglesAndStatusesUseReadingsNotInferredPoses() {
    var judge = MatchJudge(target: 12, tuning: .normal, startedAt: 0)
    judge.ingest(reading(16, time: 0, pose: .closed))
    judge.tick(now: 1)
    #expect(judge.state == .matched(error: 4, time: 1))
}
