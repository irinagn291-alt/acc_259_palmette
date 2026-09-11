import SwiftUI

/// Role: NodeMark. Own screen for pinch-then-node, plus the pinch surface on Garden.
struct PinchThenNode: View {
    var watch: GardenWatch
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TrellisRail.space(2)) {
                    Image(TrellisPlate.twistHero)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: TrellisRail.space(28))
                        .background(TrellisInk.Palette.surface)
                        .clipShape(TrellisRail.cardShape)
                        .accessibilityHidden(true)
                    Text("Pinch, then a node")
                        .trellisInk(.trellis)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text("Pouring cash only lengthens waiting flush on the leader. The hatched wood and the node beads do not move.")
                        .font(TrellisFace.font(.body))
                        .foregroundStyle(TrellisInk.Palette.ink)
                    Text("Pinch the leader to move every unit of waiting cash into wood. A bead writes for each quarter of that vine’s own target that wood newly reaches: 25, 50, 75, and 100 percent.")
                        .font(TrellisFace.font(.body))
                        .foregroundStyle(TrellisInk.Palette.ink)
                    Text("A cane that looks halfway still has no beads until you pinch. Retract peels waiting cash only. Pinching with nothing waiting does nothing.")
                        .font(TrellisFace.font(.body))
                        .foregroundStyle(TrellisInk.Palette.ink)
                    if let vine = watch.openVine {
                        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
                            Text(vine.name)
                                .trellisInk(.heading)
                                .lineLimit(1)
                            HStack(spacing: TrellisRail.space(2)) {
                                figure(TrellisFigures.money(vine.leader.wood.amount), "Wood")
                                figure(TrellisFigures.money(vine.leader.flush.amount), "Waiting")
                                figure(TrellisFigures.count(vine.nodeMarks.count), "Beads")
                            }
                            Text(watch.canPinchLeader ? watch.pinchDetail : "Pour first, then pinch.")
                                .font(TrellisFace.font(.callout))
                                .foregroundStyle(TrellisInk.Palette.ink)
                            if !vine.nodeMarks.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: TrellisRail.space(1)) {
                                        ForEach(vine.nodeMarks) { mark in
                                            TrellisChip(title: TrellisFigures.quartile(mark.quartile))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
                            }
                        }
                        .padding(TrellisRail.space(2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .trellisCard()
                    }
                    if watch.canPinchLeader {
                        TrellisCapsule(
                            title: "Pinch the leader",
                            artwork: TrellisPlate.controlFace,
                            fills: true,
                            emphasized: true,
                            enabled: !watch.isCommitting,
                            busy: watch.isCommitting
                        ) {
                            Task {
                                await watch.pinchLeader()
                                close()
                            }
                        }
                    } else {
                        TrellisCapsule(
                            title: "Back to the garden",
                            fills: true,
                            emphasized: true
                        ) {
                            watch.tab = .garden
                            close()
                        }
                    }
                }
                .padding(TrellisRail.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, TrellisRail.space(3), for: .scrollContent)
            .background(TrellisInk.Palette.background.ignoresSafeArea())
            .navigationTitle("Pinch, then a node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: TrellisRail.tap, height: TrellisRail.tap)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(TrellisRail.cardRadius)
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(TrellisFace.font(.figure))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(TrellisFace.font(.caption))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func close() {
        onClose?()
        dismiss()
    }
}
