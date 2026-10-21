import Testing

@testable import DuoCore

@Test func scoringDecreasesWithErrorAndElapsedTime() {
    let tuning = Tuning.normal
    for time in [0.0, 1, 5, 14] {
        let scores = [0.0, 1, 2, 3, 4].map { Scoring.points(error: $0, elapsed: time, tuning: tuning) }
        #expect(zip(scores, scores.dropFirst()).allSatisfy { $0 >= $1 })
    }
    for error in [0.0, 1, 2, 4] {
        let scores = [0.0, 1, 5, 14].map { Scoring.points(error: error, elapsed: $0, tuning: tuning) }
        #expect(zip(scores, scores.dropFirst()).allSatisfy { $0 >= $1 })
    }
    #expect(Scoring.points(error: 0, elapsed: 0, tuning: tuning) == Scoring.maximumPoints)
}

@Test func scoringRejectsMissesTimeoutsAndInvalidNumbers() {
    #expect(Scoring.points(error: 5, elapsed: 1, tuning: .normal) == 0)
    #expect(Scoring.points(error: 0, elapsed: 15, tuning: .normal) == 0)
    #expect(Scoring.points(error: -1, elapsed: 1, tuning: .normal) == 0)
    #expect(Scoring.points(error: .nan, elapsed: 1, tuning: .normal) == 0)
    #expect(Scoring.points(error: 0, elapsed: .infinity, tuning: .normal) == 0)
}
