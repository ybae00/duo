import DuoCore
import SwiftUI

@main
struct DuoApp: App {
    @State private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onHingeChange { _, context in
                    model.receive(context.hinge)
                }
                .onChange(of: scenePhase) { _, phase in
                    model.setActive(phase == .active)
                }
        }
    }
}
