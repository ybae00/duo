import SwiftUI

struct ContentView: View {
    @Bindable var model: ProbeModel

    var body: some View {
        Form {
            Section("Duo hinge probe · simulator experiment") {
                LabeledContent("Angle", value: number(model.degrees, suffix: "°"))
                LabeledContent("Status", value: model.status)
                LabeledContent("Callbacks", value: "\(model.callbackCount)")
                LabeledContent("Nil callbacks", value: "\(model.nilCount)")
                LabeledContent("Latest elapsed", value: number(model.latestElapsed, suffix: " s"))
                LabeledContent("Latest interval", value: number(model.latestInterval, suffix: " s"))
                LabeledContent("Observed minimum", value: number(model.minimum, suffix: "°"))
                LabeledContent("Observed maximum", value: number(model.maximum, suffix: "°"))
            }

            Section("Measurement controls") {
                Picker("Phase", selection: $model.phase) {
                    ForEach(ProbeModel.phases, id: \.self) { phase in
                        Text(phase).tag(phase)
                    }
                }
                .onChange(of: model.phase) { _, _ in model.record("phaseChanged") }
                Button("Add state marker (\(model.markerCount))") {
                    model.markerCount += 1
                    model.record("marker")
                }
                Text(
                    "The run ID, callback count, and markers should survive folds. Intervals measure callbacks, not a promised sensor rate."
                )
                .font(.footnote)
            }

            Section("Local log") {
                LabeledContent("Run ID", value: model.runID)
                Text(model.logURL.lastPathComponent)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                Text(
                    "Every callback, including nil, is written to Documents as JSONL and printed to the debug console. No synthetic hinge input is used."
                )
                .font(.footnote)
                if let error = model.logError {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .monospacedDigit()
    }

    private func number(_ value: Double?, suffix: String) -> String {
        value.map { String(format: "%.3f", $0) + suffix } ?? "—"
    }
}
