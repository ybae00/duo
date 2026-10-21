import Foundation
import Testing

@testable import DuoCore

private struct FixedGenerator: RandomNumberGenerator {
    private var state: UInt64 = 123_456

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

@Test func aRunHasFiveRoundsAndTotalsTheirScores() throws {
    let range = try #require(PlayableRange(low: 8, high: 172))
    var run = RunEngine(range: range, tuning: .normal)
    var rng = FixedGenerator()
    var now = 0.0

    for round in 1...RunEngine.roundCount {
        let current = HingeReading(degrees: 90, pose: .partial, time: now)
        #expect(run.startNext(current: current, now: now, using: &rng))
        #expect(run.roundNumber == round)
        let target = try #require(run.target)
        #expect(abs(target - 90) >= 18)
        if let previous = run.results.last?.target {
            #expect(abs(target - previous) >= 18)
        }
        run.ingest(HingeReading(degrees: Double(target), pose: .partial, time: now + 0.25))
        let completed = run.tick(now: now + 1.25)
        let result = try #require(completed)
        #expect(result.number == round)
        #expect(result.target == target)
        #expect(result.score > 0)
        #expect(run.target == nil)
        now += 2
    }

    #expect(run.isComplete)
    #expect(run.results.count == 5)
    #expect(run.totalScore == run.results.map(\.score).reduce(0, +))
    let saved = try JSONEncoder().encode(run.results)
    #expect(try JSONDecoder().decode([RoundResult].self, from: saved) == run.results)
    #expect(
        !run.startNext(
            current: HingeReading(degrees: 90, pose: .partial, time: now), now: now, using: &rng
        ))
}

@Test func roundStartRequiresAFreshReadingOutsideTheTarget() throws {
    let range = try #require(PlayableRange(low: 8, high: 172))
    var run = RunEngine(range: range, tuning: .normal)
    var rng = FixedGenerator()
    #expect(
        !run.startNext(
            current: HingeReading(degrees: 90, pose: .partial, time: 0), now: 31, using: &rng
        ))
    #expect(
        !run.startNext(
            current: HingeReading(degrees: 90, pose: .unknown, time: 31), now: 31, using: &rng
        ))
    #expect(run.results.isEmpty)
    #expect(run.target == nil)
}

@Test func timeoutScoresZeroAndNextRoundCanStart() throws {
    let range = try #require(PlayableRange(low: 8, high: 172))
    var run = RunEngine(range: range, tuning: .normal)
    var rng = FixedGenerator()
    #expect(run.startNext(current: HingeReading(degrees: 90, pose: .partial, time: 0), now: 0, using: &rng))
    let completed = run.tick(now: 15)
    let result = try #require(completed)
    #expect(result.error == nil)
    #expect(result.score == 0)
    #expect(run.startNext(current: HingeReading(degrees: 90, pose: .partial, time: 15), now: 15, using: &rng))
}

@Test func aPausedRoundNeedsFreshInputAndDoesNotTimeOutInBackground() throws {
    let range = try #require(PlayableRange(low: 8, high: 172))
    var run = RunEngine(range: range, tuning: .normal)
    var rng = FixedGenerator()
    #expect(run.startNext(current: HingeReading(degrees: 90, pose: .partial, time: 0), now: 0, using: &rng))
    let target = try #require(run.target)
    run.ingest(HingeReading(degrees: Double(target), pose: .partial, time: 0.5))
    run.suspend(at: 0.75)
    run.tick(now: 100)
    #expect(run.judge?.remainingTime(at: 100) == 14.25)
    run.resume(at: 100)
    #expect(run.results.isEmpty)
    #expect(run.judge?.state == .searching)
    run.tick(now: 100.5)
    #expect(run.results.isEmpty)
    run.ingest(HingeReading(degrees: Double(target), pose: .partial, time: 100.5))
    #expect(run.tick(now: 101.5)?.score ?? 0 > 0)
}
