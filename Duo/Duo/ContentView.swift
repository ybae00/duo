import DuoCore
import SwiftUI

private enum Theme {
    static let background = Color.white
    static let surface = Color(red: 0.94, green: 0.97, blue: 1)
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let muted = Color(red: 0.40, green: 0.40, blue: 0.43)
    static let accent = Color(red: 0, green: 0.40, blue: 0.80)
}

struct ContentView: View {
    let model: GameModel

    var body: some View {
        HingeLayout {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("DUO")
                        .font(.system(size: 18, weight: .semibold))
                    if model.hasHinge == false {
                        unavailable
                    } else if model.hasHinge == nil {
                        waiting
                    } else {
                        switch model.screen {
                        case .home: home
                        case .calibration: calibration
                        case .guess: guess
                        case .result: result
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: 560, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .tint(Theme.accent)
        .preferredColorScheme(.light)
        .alert(
            "Hinge reading needed",
            isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })
        ) {
            Button("OK", role: .cancel) { model.message = nil }
        } message: {
            Text(model.message ?? "Move the hinge gently, then tap Done again.")
        }
        .task(id: model.waitingSince) {
            do {
                try await Task.sleep(for: .seconds(5))
                model.finishHingeWait()
            } catch {}
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading("Guess the angle.")
            description("Start, fold your phone to the target, then tap Done.")
            primary("Start") { model.start() }
        }
    }

    private var guess: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading("Make this angle.")
            VStack(alignment: .leading, spacing: 8) {
                label("TARGET")
                Text(model.target.map { "\($0)°" } ?? "—")
                    .font(.system(size: 64, weight: .medium))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityIdentifier("guess-target")
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Theme.accent)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            description("Take your time. Tap Done when it feels right.")
            primary("Done") { model.done() }
        }
    }

    private var result: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading("Your guess.")
            if let result = model.result {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        label("TARGET")
                        Text("\(result.target)°")
                            .font(.system(size: 28, weight: .medium))
                            .monospacedDigit()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        label("ACTUAL")
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(String(format: "%.1f°", result.actual))
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(Theme.accent)
                                .minimumScaleFactor(0.5)
                                .accessibilityIdentifier("guess-actual")
                            Text(result.percentageOff.map { String(format: "%.1f%% off", $0) } ?? "—% off")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.muted)
                                .accessibilityIdentifier("guess-percentage")
                        }
                        .monospacedDigit()
                        .lineLimit(1)
                    }
                }
            }
            primary("Start") { model.start() }
        }
    }

    private var calibration: some View {
        VStack(alignment: .leading, spacing: 24) {
            label("ONE-TIME HINGE SETUP")
            if model.calibration.phase == .closing {
                heading("Close it fully.")
                description("Close your phone all the way, then continue.")
                calibrationReading
                primary("Continue") { model.beginOpening() }
            } else {
                heading("Open it flat.")
                description("Open your phone fully so Duo can measure its range.")
                calibrationReading
                if model.calibrationError == nil {
                    primary("Start") { model.finishCalibration() }
                }
            }
            if let error = model.calibrationError {
                description(calibrationMessage(error))
                primary("Retry setup") { model.startCalibration() }
            }
        }
    }

    private var calibrationReading: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("HINGE ANGLE")
            Text(model.calibrationAngleText)
                .font(.system(size: 28, weight: .medium))
                .monospacedDigit()
        }
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading("No hinge detected.")
            description("Duo needs an iPhone Duo with iOS 27.1 or later. Move the hinge or retry.")
            primary("Retry") { model.retryHinge() }
        }
    }

    private var waiting: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading("Give it a fold.")
            description("Waiting for a hinge reading. Move your phone gently.")
            ProgressView().tint(Theme.accent)
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text).font(.system(size: 28, weight: .semibold))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .medium))
    }

    private func description(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.background)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func calibrationMessage(_ error: CalibrationFailure) -> String {
        switch error {
        case .noReadings: "No hinge readings yet. Move the phone and retry setup."
        case .noOpeningReading: "No opening reading yet. Retry setup and open fully."
        case .rangeTooNarrow: "The measured range is too small. Retry setup, closing and opening fully."
        }
    }
}

private struct HingeLayout<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geometry in
            if let division = geometry.reservedRegions(kind: .division).first(where: \.isActive) {
                let frame = division.frame.intersection(CGRect(origin: .zero, size: geometry.size))
                if frame.height > frame.width {
                    let left = max(0, frame.minX)
                    let right = max(0, geometry.size.width - frame.maxX)
                    HStack(spacing: 0) {
                        if left >= right { content.frame(width: left) } else { companion.frame(width: left) }
                        Color.clear.frame(width: max(0, frame.width))
                        if left >= right { companion.frame(width: right) } else { content.frame(width: right) }
                    }
                } else {
                    let top = max(0, frame.minY)
                    let bottom = max(0, geometry.size.height - frame.maxY)
                    VStack(spacing: 0) {
                        if top >= bottom { content.frame(height: top) } else { companion.frame(height: top) }
                        Color.clear.frame(height: max(0, frame.height))
                        if top >= bottom { companion.frame(height: bottom) } else { content.frame(height: bottom) }
                    }
                }
            } else {
                content
            }
        }
    }

    private var companion: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.split.2x1").font(.system(size: 24, weight: .thin))
            Text("DUO").font(.system(size: 24, weight: .semibold))
            Text("ONE MOVE. TWO HALVES.").font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(Theme.accent).padding(10).frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}
