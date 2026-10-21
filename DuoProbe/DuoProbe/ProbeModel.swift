import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ProbeModel {
    static let phases = ["Presets", "Opening", "Closing", "Point clicks", "Still", "Closed hold"]

    let runID = UUID().uuidString
    let logURL: URL
    var degrees: Double?
    var status = "Waiting for first callback"
    var callbackCount = 0
    var nilCount = 0
    var minimum: Double?
    var maximum: Double?
    var latestElapsed: Double?
    var latestInterval: Double?
    var phase = "Presets"
    var markerCount = 0
    var logError: String?

    @ObservationIgnored private let start = ProcessInfo.processInfo.systemUptime
    @ObservationIgnored private var previousCallback: Double?
    @ObservationIgnored private var writer: FileHandle?

    init() {
        logURL = URL.documentsDirectory.appendingPathComponent("hinge-probe-\(runID).jsonl")
        do {
            try Data().write(to: logURL, options: .withoutOverwriting)
            writer = try FileHandle(forWritingTo: logURL)
        } catch {
            logError = "Cannot open log: \(error.localizedDescription)"
        }
        record("runStarted")
    }

    func receive(_ hinge: DeviceHinge?) {
        let now = ProcessInfo.processInfo.systemUptime
        callbackCount += 1
        latestInterval = previousCallback.map { now - $0 }
        previousCallback = now
        latestElapsed = now - start
        degrees = hinge?.angle.degrees
        if let hinge {
            status = Self.label(for: hinge.status)
            let angle = hinge.angle.degrees
            minimum = minimum.map { min($0, angle) } ?? angle
            maximum = maximum.map { max($0, angle) } ?? angle
        } else {
            nilCount += 1
            status = "Hinge unavailable"
        }
        record("hinge", uptime: now)
    }

    func record(_ kind: String, uptime: Double? = nil) {
        let event = Event(
            kind: kind,
            runID: runID,
            unixTime: Date().timeIntervalSince1970,
            elapsed: (uptime ?? ProcessInfo.processInfo.systemUptime) - start,
            callback: callbackCount,
            degrees: degrees,
            status: status,
            phase: phase,
            marker: markerCount
        )
        do {
            var data = try JSONEncoder().encode(event)
            print("DUO_PROBE \(String(decoding: data, as: UTF8.self))")
            data.append(0x0A)
            try writer?.write(contentsOf: data)
        } catch {
            logError = "Cannot write log: \(error.localizedDescription)"
        }
    }

    private static func label(for status: DeviceHinge.Status) -> String {
        if status == .closed { return "closed" }
        if status == .partiallyOpen { return "partiallyOpen" }
        if status == .fullyOpen { return "fullyOpen" }
        return "unknown"
    }

    private struct Event: Encodable {
        let kind: String
        let runID: String
        let unixTime: Double
        let elapsed: Double
        let callback: Int
        let degrees: Double?
        let status: String
        let phase: String
        let marker: Int
    }
}
