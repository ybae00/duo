import SwiftUI

@main
struct DuoProbeApp: App {
    @State private var model = ProbeModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onHingeChange { _, context in
                    model.receive(context.hinge)
                }
                .onAppear { model.record("rootAppeared") }
                .onDisappear { model.record("rootDisappeared") }
                .onChange(of: scenePhase) { _, phase in
                    model.record("scenePhase:\(phase)")
                }
        }
    }
}
