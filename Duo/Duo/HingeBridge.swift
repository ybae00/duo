import DuoCore
import Foundation
import SwiftUI

enum HingeBridge {
    static func reading(from hinge: DeviceHinge, at time: TimeInterval) -> HingeReading? {
        let degrees = hinge.angle.degrees
        guard degrees.isFinite else { return nil }
        return HingeReading(degrees: degrees, pose: pose(for: hinge.status), time: time)
    }

    private static func pose(for status: DeviceHinge.Status) -> Pose {
        if status == .closed { return .closed }
        if status == .partiallyOpen { return .partial }
        if status == .fullyOpen { return .open }
        return .unknown
    }
}
