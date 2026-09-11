import SwiftUI

/// Role: Vine. Three pages. Skip still writes the completion flag. Re-runnable from Settings.
struct GardenPassage: View {
    var watch: GardenWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let last = 2

    var body: some View {
        VStack(spacing: TrellisRail.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: TrellisPlate.onboarding1,
                        title: "Plant a goal on the garden",
                        line: "Name a target. The garden is a trellis of glass canes you grow by hand — not a bank."
                    )
                case 1:
                    pageView(
                        image: TrellisPlate.onboarding2,
                        title: "Pour, then pinch the leader",
                        line: "Adding cash lengthens waiting flush. Pinch the leader to lock it into wood."
                    )
                default:
                    pageView(
                        image: TrellisPlate.onboarding3,
                        title: "Beads only after a pinch",
                        line: "Node beads appear when wood crosses a quarter of that vine’s target. Waiting cash never beads."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : TrellisRail.motion, value: page)
            TrellisCapsule(
                title: page < last ? "Next" : "Continue",
                fills: true,
                emphasized: true,
                busy: watch.isCommitting
            ) {
                if page < last {
                    page += 1
                } else {
                    Task { await watch.finishOnboarding() }
                }
            }
            Button {
                Task { await watch.finishOnboarding() }
            } label: {
                Text("Skip")
                    .trellisInk(.body)
                    .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TrellisPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Skip")
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TrellisInk.Palette.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: TrellisRail.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .trellisInk(.trellis)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(TrellisFace.font(.body))
                .foregroundStyle(TrellisInk.Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
