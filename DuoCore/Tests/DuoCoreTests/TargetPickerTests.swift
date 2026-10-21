import Testing

@testable import DuoCore

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
        value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
        return value ^ (value >> 31)
    }
}

@Test func targetsStayWithinRangeAndAwayFromTheCurrentAndPreviousAngle() throws {
    let range = try #require(PlayableRange(low: 11.3, high: 167.8))
    var generator = SeededGenerator(state: 12)
    var previous: Int? = 90

    for _ in 0..<100 {
        let next = try #require(
            TargetPicker.pick(
                in: range, previous: previous, currentDegrees: 84.2,
                tuning: .normal, using: &generator
            ))
        #expect((12...167).contains(next))
        #expect(abs(Double(next) - 84.2) >= Tuning.normal.minimumTargetDistance)
        if let previous {
            #expect(abs(next - previous) >= Int(Tuning.normal.minimumTargetDistance))
        }
        previous = next
    }
}

@Test func seededTargetSequenceIsRepeatable() throws {
    let range = try #require(PlayableRange(low: 8, high: 172))
    var first = SeededGenerator(state: 2026)
    var second = SeededGenerator(state: 2026)

    for _ in 0..<40 {
        let firstTarget = TargetPicker.pick(
            in: range, previous: 50, currentDegrees: 100,
            tuning: .normal, using: &first
        )
        let secondTarget = TargetPicker.pick(
            in: range, previous: 50, currentDegrees: 100,
            tuning: .normal, using: &second
        )
        #expect(firstTarget == secondTarget)
    }
}

@Test func pickerReturnsNilIfNoEligibleTargetExists() throws {
    let narrow = try #require(PlayableRange(low: 20.1, high: 20.9))
    let nearby = try #require(PlayableRange(low: 20, high: 24))
    var generator = SeededGenerator(state: 1)
    #expect(
        TargetPicker.pick(
            in: narrow, previous: nil, currentDegrees: 50,
            tuning: .normal, using: &generator) == nil)
    #expect(
        TargetPicker.pick(
            in: nearby, previous: 20, currentDegrees: 21,
            tuning: .normal, using: &generator) == nil)
    #expect(
        TargetPicker.pick(
            in: nearby, previous: nil, currentDegrees: .nan,
            tuning: .normal, using: &generator) == nil)
}
