import SwiftUI

/// Role: Leader. Pinch and retract fused on the open vine. Pinch is the only fold that writes Wood and NodeMarks.
struct PinchLeaderFold: View {
    var watch: GardenWatch
    var compact: Bool = false
    var showsRetract: Bool = true
    var onPinch: () -> Void
    var onRetract: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            TrellisCapsule(
                title: "Pinch the leader",
                detail: compact ? nil : watch.pinchDetail,
                artwork: TrellisPlate.controlFace,
                fills: true,
                emphasized: true,
                enabled: watch.canPinchLeader,
                busy: watch.isCommitting,
                hint: "Moves waiting cash into wood and writes node beads at quarter crossings."
            ) {
                TrellisKeyboard.dismiss()
                onPinch()
            }
            if showsRetract {
                TrellisCapsule(
                    title: "Retract",
                    detail: compact ? nil : "Peels waiting cash only. Wood and beads stay.",
                    fills: true,
                    emphasized: false,
                    enabled: watch.canRetract,
                    busy: watch.isCommitting,
                    hint: "Removes waiting cash down to zero. Wood stays."
                ) {
                    TrellisKeyboard.dismiss()
                    onRetract()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Role: Leader. Material card that fuses pour, pinch, and retract on the open vine.
struct LeaderDock: View {
    var watch: GardenWatch
    @Binding var draft: String
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            if !compact, let vine = watch.openVine {
                HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(2)) {
                    figure(TrellisFigures.money(vine.leader.wood.amount), "Wood")
                    figure(TrellisFigures.money(vine.leader.flush.amount), "Waiting")
                    figure(TrellisFigures.money(vine.target), "Target")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(vine.name). Wood \(TrellisFigures.money(vine.leader.wood.amount)), waiting \(TrellisFigures.money(vine.leader.flush.amount)), target \(TrellisFigures.money(vine.target))"
                )
            }
            PourFold(watch: watch, draft: $draft, showsCommit: !compact, compact: compact) { amount in
                commitPour(amount)
            }
            PinchLeaderFold(
                watch: watch,
                compact: compact,
                showsRetract: !compact,
                onPinch: { Task { await watch.pinchLeader() } },
                onRetract: { Task { await watch.retractFlush() } }
            )
            if compact {
                HStack(spacing: TrellisRail.space(1)) {
                    TrellisCapsule(
                        title: "Pour",
                        fills: true,
                        emphasized: false,
                        enabled: TrellisFigures.parseDecimal(draft) != nil && watch.openVine != nil,
                        busy: watch.isCommitting,
                        hint: "Adds cash to waiting flush. Does not write wood."
                    ) {
                        if let amount = TrellisFigures.parseDecimal(draft) {
                            commitPour(amount)
                        }
                    }
                    TrellisCapsule(
                        title: "Retract",
                        fills: true,
                        emphasized: false,
                        enabled: watch.canRetract,
                        busy: watch.isCommitting,
                        hint: "Removes waiting cash down to zero. Wood stays."
                    ) {
                        TrellisKeyboard.dismiss()
                        Task { await watch.retractFlush() }
                    }
                }
                .frame(minHeight: TrellisRail.tap)
            }
        }
        .padding(compact ? TrellisRail.space(1) : TrellisRail.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .trellisCard()
    }

    private func commitPour(_ amount: Double) {
        TrellisKeyboard.dismiss()
        Task {
            await watch.pour(amount: amount)
            if watch.fault == nil {
                draft = ""
            }
        }
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(TrellisFace.font(.figure))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text(caption)
                .font(TrellisFace.font(.caption))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
