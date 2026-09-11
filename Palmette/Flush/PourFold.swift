import SwiftUI

/// Role: Flush. Amount field and pour Capsule fused on the open vine. Writes Flush only.
struct PourFold: View {
    var watch: GardenWatch
    @Binding var draft: String
    var showsCommit: Bool = true
    var compact: Bool = false
    var onPour: (Double) -> Void

    private let chips: [Double] = [10, 25, 50]

    var body: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            if showsCommit {
                Text("Pour cash")
                    .trellisInk(.heading)
                    .lineLimit(1)
                Text("Waiting cash lengthens the cane. Wood and beads do not move yet.")
                    .font(TrellisFace.font(.caption))
                    .foregroundStyle(TrellisInk.Palette.ink)
            }
            if compact {
                HStack(spacing: TrellisRail.space(1)) {
                    amountField
                    ForEach(chips, id: \.self) { amount in
                        TrellisChip(title: TrellisFigures.money(amount)) {
                            TrellisKeyboard.dismiss()
                            onPour(amount)
                        }
                    }
                }
            } else {
                HStack(spacing: TrellisRail.space(1)) {
                    ForEach(chips, id: \.self) { amount in
                        TrellisChip(title: TrellisFigures.money(amount)) {
                            TrellisKeyboard.dismiss()
                            onPour(amount)
                        }
                    }
                }
                amountField
            }
            if showsCommit {
                TrellisCapsule(
                    title: "Pour onto the leader",
                    fills: true,
                    emphasized: false,
                    enabled: TrellisFigures.parseDecimal(draft) != nil && watch.openVine != nil,
                    busy: watch.isCommitting,
                    hint: "Adds cash to waiting flush. Does not write wood."
                ) {
                    if let amount = TrellisFigures.parseDecimal(draft) {
                        TrellisKeyboard.dismiss()
                        onPour(amount)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var amountField: some View {
        TextField("Amount", text: $draft)
            .keyboardType(.decimalPad)
            .textFieldStyle(.plain)
            .font(TrellisFace.font(.body).monospacedDigit())
            .foregroundStyle(TrellisInk.Palette.ink)
            .padding(.horizontal, TrellisRail.space(2))
            .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
            .background(TrellisInk.Palette.surface)
            .clipShape(TrellisRail.chipShape)
            .overlay {
                TrellisRail.chipShape.stroke(TrellisInk.Palette.ink.opacity(0.18), lineWidth: 1)
            }
            .onChange(of: draft) { _, next in
                let cleaned = TrellisFigures.sanitizeDecimal(next)
                if cleaned != next { draft = cleaned }
            }
            .accessibilityLabel("Pour amount")
    }
}
