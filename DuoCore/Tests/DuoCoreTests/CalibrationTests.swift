import Testing

@testable import DuoCore

@Test func calibrationKeepsMeasuredStatusAndTrimsBothEnds() throws {
    var calibration = Calibration()
    calibration.ingest(HingeReading(degrees: 0, pose: .closed, time: 1))
    calibration.ingest(HingeReading(degrees: 8, pose: .partial, time: 2))
    calibration.beginOpening()
    calibration.ingest(HingeReading(degrees: 12, pose: .partial, time: 3))
    calibration.ingest(HingeReading(degrees: 180, pose: .open, time: 4))

    #expect(calibration.phase == .opening)
    #expect(calibration.closedAngle == 0)
    #expect(calibration.fullyOpenAngle == 180)
    #expect(calibration.lowestSeen == 0)
    #expect(calibration.highestSeen == 180)
    let range = try calibration.finish(tuning: .normal).get()
    #expect(range == PlayableRange(low: 8, high: 172))
}

@Test func calibrationWorksWithoutClosedCallbacks() throws {
    var calibration = Calibration()
    calibration.beginOpening()
    calibration.ingest(HingeReading(degrees: 12, pose: .partial, time: 1))
    calibration.ingest(HingeReading(degrees: 170, pose: .open, time: 2))

    #expect(calibration.closedAngle == nil)
    #expect(try calibration.finish(tuning: .normal).get() == PlayableRange(low: 20, high: 162))
}

@Test func calibrationFailsWhenSpanIsTooNarrow() {
    var calibration = Calibration()
    calibration.ingest(HingeReading(degrees: 40, pose: .closed, time: 1))
    calibration.beginOpening()
    calibration.ingest(HingeReading(degrees: 70, pose: .open, time: 2))
    #expect(calibration.finish(tuning: .normal) == .failure(.rangeTooNarrow))
}

@Test func calibrationNeedsAnOpeningReading() {
    var calibration = Calibration()
    #expect(calibration.finish(tuning: .normal) == .failure(.noReadings))
    calibration.ingest(HingeReading(degrees: 0, pose: .closed, time: 1))
    calibration.beginOpening()
    #expect(calibration.finish(tuning: .normal) == .failure(.noOpeningReading))
}

@Test func calibrationIgnoresUnknownAndNonfiniteReadings() {
    var calibration = Calibration()
    calibration.ingest(HingeReading(degrees: 0, pose: .unknown, time: 1))
    calibration.ingest(HingeReading(degrees: .nan, pose: .closed, time: 2))
    calibration.beginOpening()
    calibration.ingest(HingeReading(degrees: 180, pose: .open, time: .infinity))
    #expect(calibration.finish(tuning: .normal) == .failure(.noReadings))
}

@Test func playableRangeRejectsInvalidBounds() {
    #expect(PlayableRange(low: 0, high: 0) == nil)
    #expect(PlayableRange(low: .nan, high: 10) == nil)
    #expect(PlayableRange(low: 10, high: .infinity) == nil)
}
