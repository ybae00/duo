import Foundation

public enum TargetPicker {
    public static func pick<R: RandomNumberGenerator>(
        in range: PlayableRange,
        using generator: inout R
    ) -> Int? {
        guard let low = Int(exactly: ceil(range.low)),
            let high = Int(exactly: floor(range.high)), low <= high
        else { return nil }
        return Int.random(in: low...high, using: &generator)
    }

    public static func pick<R: RandomNumberGenerator>(
        in range: PlayableRange,
        previous: Int?,
        currentDegrees: Double,
        tuning: Tuning,
        using generator: inout R
    ) -> Int? {
        guard currentDegrees.isFinite,
            let low = Int(exactly: ceil(range.low)),
            let high = Int(exactly: floor(range.high)),
            low <= high
        else { return nil }

        let candidates = (low...high).filter { target in
            let degrees = Double(target)
            return (previous.map { abs(degrees - Double($0)) >= tuning.minimumTargetDistance } ?? true)
                && abs(degrees - currentDegrees) >= tuning.minimumTargetDistance
                && abs(degrees - currentDegrees) > tuning.tolerance
        }
        guard !candidates.isEmpty else { return nil }
        return candidates[Int.random(in: 0..<candidates.count, using: &generator)]
    }
}
