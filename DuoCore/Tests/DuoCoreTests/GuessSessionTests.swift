import Testing

@testable import DuoCore

private struct GuessGenerator: RandomNumberGenerator {
    var state: UInt64 = 123_456

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

private func fixedTargetSession() throws -> GuessSession {
    let range = try #require(PlayableRange(low: 89.9, high: 90.1))
    return GuessSession(range: range)
}

@Test func manualGuessUsesTheLatestAngleOnlyWhenSubmitted() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    session.ingest(HingeReading(degrees: 40, pose: .partial, time: 1))
    session.ingest(HingeReading(degrees: 81, pose: .partial, time: 2))
    #expect(session.state == .guessing(target: 90))
    let acceptedSubmission = session.submit()
    #expect(acceptedSubmission)
    #expect(session.state == .result(try #require(GuessResult(target: 90, actual: 81))))
}

@Test func evenAnExactMatchWaitsForDoneWithoutAHoldOrDeadline() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    session.ingest(HingeReading(degrees: 90, pose: .partial, time: 1))
    #expect(session.state == .guessing(target: 90))
    session.ingest(HingeReading(degrees: 90, pose: .partial, time: 100_000))
    #expect(session.state == .guessing(target: 90))
    let acceptedSubmission = session.submit()
    #expect(acceptedSubmission)
}

@Test func aStationaryReadingHasNoAgeLimitForManualSubmission() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    session.ingest(HingeReading(degrees: 81, pose: .partial, time: 1))
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    let acceptedSubmission = session.submit()
    #expect(acceptedSubmission)
    #expect(session.state == .result(try #require(GuessResult(target: 90, actual: 81))))
}

@Test func guessesOutsideTheOldToleranceStillProduceComparisons() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    session.ingest(HingeReading(degrees: 170, pose: .open, time: 1))
    let acceptedSubmission = session.submit()
    #expect(acceptedSubmission)
    #expect(session.state == .result(try #require(GuessResult(target: 90, actual: 170))))
}

@Test func aSubmittedResultIsFrozenAsTheHingeMoves() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    session.ingest(HingeReading(degrees: 81, pose: .partial, time: 1))
    let acceptedSubmission = session.submit()
    #expect(acceptedSubmission)
    let frozen = session.state
    session.ingest(HingeReading(degrees: 120, pose: .partial, time: 2))
    let rejectedSubmission = session.submit()
    #expect(!rejectedSubmission)
    session.ingest(nil)
    #expect(session.state == frozen)
}

@Test func startCannotReplaceAnUnsubmittedTarget() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    let rejectedSubmission = session.submit()
    #expect(!rejectedSubmission)
    #expect(session.state == .ready)
    let acceptedStart = session.start(using: &generator)
    #expect(acceptedStart)
    let rejectedStart = session.start(using: &generator)
    #expect(!rejectedStart)
    #expect(session.state == .guessing(target: 90))
}

@Test func guessesCanContinueBeyondFiveWithoutARunOrScore() throws {
    var session = try fixedTargetSession()
    var generator = GuessGenerator()
    for number in 1...20 {
        let acceptedStart = session.start(using: &generator)
        #expect(acceptedStart)
        #expect(session.state == .guessing(target: 90))
        session.ingest(HingeReading(degrees: Double(number), pose: .partial, time: Double(number)))
        let acceptedSubmission = session.submit()
        #expect(acceptedSubmission)
    }
}

@Test func lostUnknownAndInvalidReadingsRequireRecoveryButKeepTheTarget() throws {
    let invalidReadings: [HingeReading?] = [
        nil,
        HingeReading(degrees: 90, pose: .unknown, time: 1),
        HingeReading(degrees: .nan, pose: .partial, time: 1),
        HingeReading(degrees: .infinity, pose: .partial, time: 1),
        HingeReading(degrees: 90, pose: .partial, time: .infinity),
    ]
    for invalid in invalidReadings {
        var session = try fixedTargetSession()
        var generator = GuessGenerator()
        let acceptedStart = session.start(using: &generator)
        #expect(acceptedStart)
        session.ingest(HingeReading(degrees: 81, pose: .partial, time: 1))
        session.ingest(invalid)
        #expect(session.reading == nil)
        let rejectedSubmission = session.submit()
        #expect(!rejectedSubmission)
        #expect(session.state == .guessing(target: 90))
        session.ingest(HingeReading(degrees: 85, pose: .partial, time: 2))
        let acceptedSubmission = session.submit()
        #expect(acceptedSubmission)
    }
}

@Test func comparisonPercentageIsAbsoluteErrorRelativeToTheTarget() throws {
    let under = try #require(GuessResult(target: 90, actual: 81))
    let over = try #require(GuessResult(target: 90, actual: 99))
    #expect(under.error == 9)
    #expect(under.percentageOff == 10)
    #expect(over.percentageOff == 10)
    #expect(GuessResult(target: 90, actual: 90)?.percentageOff == 0)
    #expect(GuessResult(target: 30, actual: 120)?.percentageOff == 300)
    #expect(GuessResult(target: -90, actual: -81)?.percentageOff == 10)
    #expect(GuessResult(target: 0, actual: 0)?.percentageOff == 0)
    #expect(GuessResult(target: 0, actual: 1)?.percentageOff == nil)
}

@Test func percentageViewShowsClosenessNotPointsOrPercentageOff() throws {
    #expect(GuessResult(target: 90, actual: 90)?.percentageCloseness == 100)
    #expect(GuessResult(target: 90, actual: 81)?.percentageCloseness == 90)
    #expect(GuessResult(target: 90, actual: 99)?.percentageCloseness == 90)
    #expect(GuessResult(target: 50, actual: 49)?.percentageCloseness == 98)
    #expect(GuessResult(target: 30, actual: 120)?.percentageCloseness == 0)
    #expect(GuessResult(target: -90, actual: -81)?.percentageCloseness == 90)
    #expect(GuessResult(target: 0, actual: 0)?.percentageCloseness == 100)
    #expect(GuessResult(target: 0, actual: 1)?.percentageCloseness == nil)
    #expect(GuessResult(target: 1, actual: .greatestFiniteMagnitude)?.percentageCloseness == 0)
}

@Test func invalidComparisonNumbersAreNeverDisplayedAsResults() {
    #expect(GuessResult(target: 90, actual: .nan) == nil)
    #expect(GuessResult(target: 90, actual: .infinity) == nil)
    #expect(GuessResult(target: 90, actual: -.infinity) == nil)
    #expect(GuessResult(target: 1, actual: .greatestFiniteMagnitude)?.percentageOff == nil)
}

@Test func simpleTargetsUseTheCalibratedRangeAndSeededRandomness() throws {
    let range = try #require(PlayableRange(low: 220.4, high: 300.6))
    var first = GuessGenerator()
    var second = GuessGenerator()
    var observed = Set<Int>()
    for _ in 0..<200 {
        let target = try #require(TargetPicker.pick(in: range, using: &first))
        #expect(target >= 221 && target <= 300)
        #expect(TargetPicker.pick(in: range, using: &second) == target)
        observed.insert(target)
    }
    #expect(observed.count > 1)
}

@Test func rangesWithoutRepresentableWholeDegreeTargetsCannotStart() throws {
    var generator = GuessGenerator()
    for range in [
        try #require(PlayableRange(low: 0.1, high: 0.9)),
        try #require(PlayableRange(low: 1e100, high: 1e101)),
    ] {
        var session = GuessSession(range: range)
        let rejectedStart = session.start(using: &generator)
        #expect(!rejectedStart)
        #expect(session.state == .ready)
    }
}

@Test func minimalCalibrationUsesMarginsWithoutGameplayDifficulty() throws {
    var calibration = Calibration()
    calibration.ingest(HingeReading(degrees: 0, pose: .closed, time: 1))
    calibration.beginOpening()
    calibration.ingest(HingeReading(degrees: 180, pose: .open, time: 2))
    #expect(try calibration.finish().get() == PlayableRange(low: 8, high: 172))
    #expect(calibration.finish(endMargin: -1) == .failure(.rangeTooNarrow))
    #expect(calibration.finish(minimumPlayableSpan: .nan) == .failure(.rangeTooNarrow))
}
