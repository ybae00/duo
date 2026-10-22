import DuoCore
import SwiftUI

private enum Theme {
    static let background = Color.white
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let muted = Color(red: 0.40, green: 0.40, blue: 0.43)
    static let accent = Color(red: 0, green: 0.40, blue: 0.80)
}

struct ContentView: View {
    let model: GameModel

    var body: some View {
        Group {
            if isHome {
                HingeLayout {
                    StartScreen { model.start() }
                } companion: {
                    companion
                }
            } else if model.hasHinge == true {
                FoldGameScreen(model: model)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("DUO")
                            .font(.system(size: 18, weight: .semibold))
                        if model.hasHinge == false {
                            unavailable
                        } else {
                            waiting
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: 560, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .ignoresSafeArea(.container, edges: isHome || model.hasHinge == true ? .all : [])
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

    private var isHome: Bool {
        model.hasHinge == true && model.screen == .home
    }

    private var companion: some View {
        StartFoldIllustration()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
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
}

private struct HingeLayout<Content: View, Companion: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var companion: Companion

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
}
