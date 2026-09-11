import SwiftUI

/// Role: Vine. Plant fuses name and target in place. Garden never pushes a record stack.
struct PlantFold: View {
    var watch: GardenWatch
    var onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var targetDraft = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TrellisRail.space(2)) {
                    TrellisSheetBar(title: "Plant a vine") {
                        close()
                    }
                    Text("Name the goal and the amount you are saving toward. The cane grows on this garden.")
                        .font(TrellisFace.font(.body))
                        .foregroundStyle(TrellisInk.Palette.ink)
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(TrellisFace.font(.body))
                        .foregroundStyle(TrellisInk.Palette.ink)
                        .padding(.horizontal, TrellisRail.space(2))
                        .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
                        .background(TrellisInk.Palette.surface)
                        .clipShape(TrellisRail.chipShape)
                        .overlay {
                            TrellisRail.chipShape.stroke(TrellisInk.Palette.ink.opacity(0.18), lineWidth: 1)
                        }
                        .accessibilityLabel("Vine name")
                    TextField("Target", text: $targetDraft)
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
                        .onChange(of: targetDraft) { _, next in
                            let cleaned = TrellisFigures.sanitizeDecimal(next)
                            if cleaned != next { targetDraft = cleaned }
                        }
                        .accessibilityLabel("Target amount")
                }
                .padding(TrellisRail.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TrellisCapsule(
                    title: "Plant",
                    fills: true,
                    emphasized: true,
                    enabled: canPlant,
                    busy: watch.isCommitting
                ) {
                    guard let target = TrellisFigures.parseDecimal(targetDraft) else { return }
                    TrellisKeyboard.dismiss()
                    Task {
                        await watch.plant(name: name, target: target)
                        close()
                    }
                }
                .padding(.horizontal, TrellisRail.space(2))
                .padding(.bottom, TrellisRail.space(2))
                .background(.regularMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TrellisInk.Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { TrellisKeyboard.dismiss() }
                        .frame(minHeight: TrellisRail.tap)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(TrellisRail.cardRadius)
    }

    private var canPlant: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && TrellisFigures.parseDecimal(targetDraft) != nil
    }

    private func close() {
        onClose()
        dismiss()
    }
}
