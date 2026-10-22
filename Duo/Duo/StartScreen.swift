import SwiftUI

struct StartScreen: View {
    let start: () -> Void

    @ScaledMetric(relativeTo: .title) private var titleSize = 28
    @ScaledMetric(relativeTo: .body) private var bodySize = 17

    private let secondary = Color(red: 135 / 255, green: 135 / 255, blue: 135 / 255)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Group {
                    if geometry.size.width >= 700, geometry.size.width > geometry.size.height {
                        HStack(spacing: 0) {
                            introduction(width: 303)
                                .padding(.horizontal, 28)
                                .frame(width: geometry.size.width / 2)
                            StartFoldIllustration()
                                .frame(width: geometry.size.width / 2)
                        }
                    } else {
                        introduction(width: 410)
                            .padding(.horizontal, 28)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func introduction(width: CGFloat) -> some View {
        VStack(spacing: 52) {
            VStack(spacing: 12) {
                Text("Foldie")
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.black)
                    .accessibilityAddTraits(.isHeader)
                Text("Start, fold your phone to the target,\nthen tap Done")
                    .font(.system(size: bodySize))
                    .foregroundStyle(secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            FoldActionButton("Start", blue: true, action: start)
                .accessibilityIdentifier("start-game")
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: width)
    }
}

struct StartFoldIllustration: View {
    var body: some View {
        Image("StartFold")
            .accessibilityHidden(true)
    }
}
