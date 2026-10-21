import DuoCore
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class GameModel {
    enum Screen {
        case home
        case calibration
        case guess
        case result
    }

    var screen: Screen = .home
    var hasHinge: Bool?
    var calibration = Calibration()
    var calibrationError: CalibrationFailure?
    var range: PlayableRange?
    var session: GuessSession?
    var message: String?
    private var calibrationReading: HingeReading?
    private(set) var waitingSince = ProcessInfo.processInfo.systemUptime

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var generator = SystemRandomNumberGenerator()
    @ObservationIgnored private var active = true

    private static let rangeKey = "duo.playableRange.v1"
    private static let initialHingeWait: TimeInterval = 5

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let values = defaults.array(forKey: Self.rangeKey) as? [Double], values.count == 2,
            let saved = PlayableRange(low: values[0], high: values[1]),
            saved.high - saved.low >= Calibration.minimumPlayableSpan
        {
            range = saved
            session = GuessSession(range: saved)
        }
    }

    var target: Int? {
        guard case .guessing(let target)? = session?.state else { return nil }
        return target
    }

    var result: GuessResult? {
        guard case .result(let result)? = session?.state else { return nil }
        return result
    }

    func receive(_ hinge: DeviceHinge?) {
        guard active else { return }
        hasHinge = hinge != nil
        let reading = hinge.flatMap { HingeBridge.reading(from: $0, at: ProcessInfo.processInfo.systemUptime) }
        if session == nil, let range { session = GuessSession(range: range) }
        session?.ingest(reading)
        if screen == .calibration, let reading { calibration.ingest(reading) }
        calibrationReading = reading?.pose == .unknown ? nil : reading
    }

    var calibrationAngleText: String {
        guard let calibrationReading else { return "—" }
        return String(format: "%.1f°", calibrationReading.degrees)
    }

    func finishHingeWait() {
        guard hasHinge == nil,
            ProcessInfo.processInfo.systemUptime - waitingSince >= Self.initialHingeWait
        else { return }
        hasHinge = false
    }

    func setActive(_ isActive: Bool) {
        guard active != isActive else { return }
        active = isActive
        session?.ingest(nil)
        calibrationReading = nil
        if isActive {
            hasHinge = nil
            waitingSince = ProcessInfo.processInfo.systemUptime
        }
    }

    func retryHinge() {
        session?.ingest(nil)
        calibrationReading = nil
        hasHinge = nil
        waitingSince = ProcessInfo.processInfo.systemUptime
    }

    func start() {
        guard active, hasHinge == true, screen != .guess else { return }
        message = nil
        guard range != nil else {
            startCalibration()
            return
        }
        guard session?.start(using: &generator) == true else {
            startCalibration()
            return
        }
        message = nil
        screen = .guess
    }

    func done() {
        guard screen == .guess else { return }
        guard active, hasHinge == true, session?.submit() == true else {
            message = "Move the hinge gently to get a reading, then tap Done again."
            return
        }
        message = nil
        screen = .result
    }

    func startCalibration() {
        calibration = Calibration()
        calibrationError = nil
        screen = .calibration
        if let calibrationReading { calibration.ingest(calibrationReading) }
    }

    func beginOpening() {
        calibration.beginOpening()
        calibrationError = nil
        if let calibrationReading { calibration.ingest(calibrationReading) }
    }

    func finishCalibration() {
        switch calibration.finish() {
        case .success(let range):
            self.range = range
            defaults.set([range.low, range.high], forKey: Self.rangeKey)
            session = GuessSession(range: range)
            session?.ingest(calibrationReading)
            calibrationError = nil
            start()
        case .failure(let error):
            calibrationError = error
        }
    }
}
