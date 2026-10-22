import DuoCore
import SwiftUI

private enum GameStyle {
    static let blue = Color(red: 0, green: 106 / 255, blue: 218 / 255)
    static let muted = Color(red: 135 / 255, green: 135 / 255, blue: 135 / 255)
    static let comparison = Color(red: 151 / 255, green: 151 / 255, blue: 151 / 255)
}

struct FoldGameScreen: View {
    let model: GameModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .title) private var headingSize = 28
    @ScaledMetric(relativeTo: .body) private var bodySize = 17
    @ScaledMetric(relativeTo: .title) private var displaySize = 64
    @ScaledMetric(relativeTo: .title) private var readingSize = 44
    @ScaledMetric(relativeTo: .title) private var secondarySize = 34
    @ScaledMetric(relativeTo: .caption) private var setupLabelSize = 15
    @ScaledMetric(relativeTo: .caption) private var toggleSize = 12
    @ScaledMetric(relativeTo: .caption) private var toggleLineHeight = 15
    @ScaledMetric(relativeTo: .body) private var actionLineHeight = 21

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= 700, geometry.size.width > geometry.size.height {
                wide(geometry)
            } else if geometry.size.width >= 600, geometry.size.height > geometry.size.width,
                case .guess = model.screen
            {
                tallGuess(geometry.size)
            } else {
                compact(geometry.size)
            }
        }
        .onChange(of: model.result, initial: true) { _, result in
            guard result != nil else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) {
                model.revealResult()
            }
        }
    }

    private func compact(_ size: CGSize) -> some View {
        ScrollView {
            Group {
                switch model.screen {
                case .calibration:
                    VStack(spacing: 52) {
                        calibrationIntroduction
                        display(model.calibrationAngleText, size: readingSize)
                            .accessibilityIdentifier("calibration-angle")
                        calibrationAction
                    }
                case .guess:
                    VStack(spacing: 0) {
                        heading("Make this angle")
                        display(model.target.map { "\($0)°" } ?? "—", size: displaySize)
                            .padding(.top, 24)
                            .accessibilityIdentifier("guess-target")
                        FoldActionButton("Done", blue: true) { model.done() }
                            .accessibilityIdentifier("guess-done")
                            .padding(.top, 52)
                    }
                case .result:
                    VStack(spacing: 0) {
                        heading("You got")
                        resultComparison
                            .padding(.top, 40)
                        FoldActionButton("Done") { model.returnToStart() }
                            .accessibilityIdentifier("result-done")
                            .padding(.top, 52)
                    }
                case .home:
                    EmptyView()
                }
            }
            .frame(maxWidth: 303)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .padding(.top, model.screen == .result && size.width < 600 ? 56 : 0)
            .frame(maxWidth: .infinity, minHeight: size.height)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func wide(_ geometry: GeometryProxy) -> some View {
        let size = geometry.size
        let division = geometry.reservedRegions(kind: .division)
            .first(where: { $0.isActive && $0.frame.height > $0.frame.width })?
            .frame.intersection(CGRect(origin: .zero, size: size))
        let leftEdge = division?.minX ?? size.width / 2
        let rightEdge = division?.maxX ?? size.width / 2
        let leftWidth = max(0, leftEdge)
        let rightWidth = max(0, size.width - rightEdge)

        switch model.screen {
        case .calibration:
            HStack(spacing: 0) {
                wideActionPanel(width: leftWidth, height: size.height) {
                    calibrationIntroduction
                } action: {
                    calibrationAction
                }
                Color.clear.frame(width: max(0, rightEdge - leftEdge))
                display(model.calibrationAngleText, size: readingSize)
                    .accessibilityIdentifier("calibration-angle")
                    .frame(width: rightWidth, height: size.height)
            }
        case .guess:
            ZStack {
                heading("Make this angle")
                    .frame(width: max(0, leftWidth - 120))
                    .position(x: leftWidth / 2, y: size.height / 2)
                display(model.target.map { "\($0)°" } ?? "—", size: displaySize)
                    .frame(width: max(0, rightWidth - 120))
                    .accessibilityIdentifier("guess-target")
                    .position(x: rightEdge + rightWidth / 2, y: size.height / 2)
                FoldActionButton("Done", blue: true) { model.done() }
                    .frame(width: 303)
                    .rotationEffect(.degrees(90))
                    .frame(width: actionThickness, height: 303)
                    .accessibilityIdentifier("guess-done-left")
                    .position(x: 23 + actionThickness / 2, y: size.height / 2)
                FoldActionButton("Done", blue: true) { model.done() }
                    .frame(width: 303)
                    .rotationEffect(.degrees(-90))
                    .frame(width: actionThickness, height: 303)
                    .accessibilityIdentifier("guess-done-right")
                    .position(x: size.width - 23 - actionThickness / 2, y: size.height / 2)
            }
            .frame(width: size.width, height: size.height)
        case .result:
            HStack(spacing: 0) {
                heading("You got")
                    .multilineTextAlignment(.center)
                    .frame(width: leftWidth, height: size.height)
                Color.clear.frame(width: max(0, rightEdge - leftEdge))
                ScrollView {
                    VStack(spacing: 52) {
                        resultComparison
                        FoldActionButton("Done") { model.returnToStart() }
                            .accessibilityIdentifier("result-done")
                    }
                    .frame(maxWidth: 303)
                    .padding(.horizontal, 28)
                    .padding(.trailing, 28)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, minHeight: size.height)
                }
                .scrollIndicators(.hidden)
                .frame(width: rightWidth, height: size.height)
            }
        case .home:
            EmptyView()
        }
    }

    private func wideActionPanel<Introduction: View, Action: View>(
        width: CGFloat, height: CGFloat,
        @ViewBuilder introduction: () -> Introduction,
        @ViewBuilder action: () -> Action
    ) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                introduction().frame(minHeight: 160)
                action()
            }
            .frame(maxWidth: 410)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, minHeight: height)
        }
        .scrollIndicators(.hidden)
        .frame(width: width, height: height)
    }

    private func tallGuess(_ size: CGSize) -> some View {
        VStack(spacing: 0) {
            FoldActionButton("Done", blue: true) { model.done() }
                .rotationEffect(.degrees(180))
                .accessibilityIdentifier("guess-done-top")
            Spacer(minLength: 24)
            heading("Make this angle")
            Spacer(minLength: 24)
            display(model.target.map { "\($0)°" } ?? "—", size: displaySize)
                .accessibilityIdentifier("guess-target")
            Spacer(minLength: 24)
            FoldActionButton("Done", blue: true) { model.done() }
                .accessibilityIdentifier("guess-done-bottom")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .frame(width: size.width, height: size.height)
    }

    private var calibrationIntroduction: some View {
        VStack(spacing: 52) {
            Text("ONE-TIME HINGE SETUP")
                .font(.system(size: setupLabelSize, weight: .medium))
                .foregroundStyle(GameStyle.blue)
            VStack(spacing: 12) {
                heading(model.calibration.phase == .closing ? "Close it fully" : "Open it flat")
                Text(
                    model.calibration.phase == .closing
                        ? "Close your phone all the way, then press continue"
                        : "Open your phone fully so Duo can measure its range"
                )
                .font(.system(size: bodySize))
                .foregroundStyle(GameStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var calibrationAction: some View {
        if let error = model.calibrationError {
            VStack(spacing: 12) {
                Text(calibrationMessage(error))
                    .font(.system(size: bodySize))
                    .foregroundStyle(GameStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
                FoldActionButton("Retry setup") { model.startCalibration() }
            }
        } else if model.calibration.phase == .closing {
            FoldActionButton("Next") { model.beginOpening() }
                .accessibilityIdentifier("calibration-next")
        } else {
            FoldActionButton("Start") { model.finishCalibration() }
                .accessibilityIdentifier("calibration-start")
        }
    }

    private var resultComparison: some View {
        VStack(spacing: 24) {
            if let result = model.result {
                resultValueLayout {
                    if model.resultShowsPercentage {
                        Group {
                            if let percentage = result.percentageCloseness {
                                resultNumber(percentage, percentage: true)
                            } else {
                                Text("—%")
                            }
                        }
                        .accessibilityIdentifier("guess-percentage")
                        Text("/100%")
                            .font(.system(size: secondarySize, weight: .medium))
                            .foregroundStyle(GameStyle.comparison)
                    } else {
                        resultNumber(result.actual)
                            .accessibilityIdentifier("guess-actual")
                        Text("/\(result.target)°")
                            .font(.system(size: secondarySize, weight: .medium))
                            .foregroundStyle(GameStyle.comparison)
                    }
                }
                .font(.system(size: displaySize, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.1)

                Button {
                    model.toggleResultView()
                } label: {
                    Text(model.resultShowsPercentage ? "View in degrees" : "View in percentage")
                        .font(.system(size: toggleSize))
                        .foregroundStyle(GameStyle.blue)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : toggleLineHeight)
                .disabled(result.percentageCloseness == nil)
                .accessibilityIdentifier("result-toggle")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func resultNumber(_ value: Double, percentage: Bool = false) -> some View {
        CountUpResultNumber(
            value: model.resultHasBeenRevealed ? value : 0,
            finalValue: value,
            percentage: percentage
        )
    }

    private var actionThickness: CGFloat {
        max(44, actionLineHeight + 20)
    }

    private var resultValueLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(spacing: 8))
        } else {
            AnyLayout(HStackLayout(alignment: .lastTextBaseline, spacing: 8))
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: headingSize, weight: .semibold))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func display(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .medium))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func calibrationMessage(_ error: CalibrationFailure) -> String {
        switch error {
        case .noReadings: "No hinge readings yet. Move the phone and retry setup."
        case .noOpeningReading: "No opening reading yet. Retry setup and open fully."
        case .rangeTooNarrow: "The measured range is too small. Retry setup, closing and opening fully."
        }
    }
}

private struct CountUpResultNumber: View, Animatable {
    var value: Double
    let finalValue: Double
    let percentage: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(formatted(finalValue))
            .hidden()
            .overlay(alignment: .trailing) {
                Text(formatted(reduceMotion ? finalValue : value))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(formatted(finalValue))
    }

    private func formatted(_ value: Double) -> String {
        percentage ? "\(Int(value.rounded()))%" : String(format: "%.1f°", value)
    }
}

struct FoldActionButton: View {
    let label: String
    var blue = false
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var labelSize = 17
    @ScaledMetric(relativeTo: .body) private var labelLineHeight = 21

    init(_ label: String, blue: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.blue = blue
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: labelSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.white)
                .frame(height: labelLineHeight)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(blue ? GameStyle.blue : .black, in: RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 303)
        .fixedSize(horizontal: false, vertical: true)
    }
}
