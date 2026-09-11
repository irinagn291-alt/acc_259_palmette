import SwiftUI

/// Role: Vine. Section 3.6 Settings tab. Named for the live driver; body is the espalier house.
struct SettingsView: View {
    var watch: GardenWatch

    var body: some View {
        EspalierHouse(watch: watch)
    }
}

/// Role: Vine. Settings. Contact, re-run onboarding, reset all data. Empty, populated, and error.
struct EspalierHouse: View {
    var watch: GardenWatch
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var confirmReset = false
    @State private var showPlant = false
    @State private var showTwist = false

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(TrellisInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                TrellisVacancy(
                    image: TrellisPlate.emptyList,
                    headline: "Settings could not be read.",
                    line: watch.fault ?? "The garden started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if !watch.onboardingComplete {
                TrellisVacancy(
                    image: TrellisPlate.emptyList,
                    headline: "The garden is not open yet.",
                    line: "Finish the first pages to keep vines, then return here.",
                    actionTitle: "Open the pages"
                ) {
                    Task { await watch.reopenOnboarding() }
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TrellisInk.Palette.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TrellisInk.Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TrellisGlyphButton(
                    systemName: "info.circle",
                    label: "How pinch writes nodes"
                ) {
                    showTwist = true
                }
            }
        }
        .sheet(isPresented: $showPlant) {
            PlantFold(watch: watch, onClose: { showPlant = false })
        }
        .sheet(isPresented: $showTwist) {
            PinchThenNode(watch: watch, onClose: { showTwist = false })
        }
        .confirmationDialog(
            "Erase every vine, pour, and node bead?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep my garden", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var populated: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            if typeSize.isAccessibilitySize {
                ScrollView {
                    VStack(alignment: .leading, spacing: TrellisRail.space(2)) {
                        if watch.isFreshGarden {
                            emptyCard(expands: false)
                        } else if wide {
                            wideGarden(size: proxy.size, expands: false)
                        } else {
                            gardenBoard(expands: false)
                        }
                        houseCard
                        faultBanner
                    }
                    .padding(.horizontal, TrellisRail.space(2))
                    .padding(.vertical, TrellisRail.space(2))
                }
                .scrollContentBackground(.hidden)
            } else if watch.isFreshGarden {
                VStack(spacing: TrellisRail.space(2)) {
                    emptyCard(expands: true)
                    houseCard
                    faultBanner
                }
                .padding(.horizontal, TrellisRail.space(2))
                .padding(.vertical, TrellisRail.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if wide {
                HStack(alignment: .top, spacing: TrellisRail.space(2)) {
                    vineSummary(expands: true)
                    VStack(spacing: TrellisRail.space(2)) {
                        pinchReminder(expands: true, showsCane: true)
                        houseCard
                        faultBanner
                    }
                    .frame(width: min(420, max(280, proxy.size.width * 0.38)))
                }
                .padding(.horizontal, TrellisRail.space(2))
                .padding(.vertical, TrellisRail.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: TrellisRail.space(2)) {
                    gardenBoard(expands: true)
                    houseCard
                    faultBanner
                }
                .padding(.horizontal, TrellisRail.space(2))
                .padding(.vertical, TrellisRail.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func wideGarden(size: CGSize, expands: Bool) -> some View {
        HStack(alignment: .top, spacing: TrellisRail.space(2)) {
            vineSummary(expands: expands)
            pinchReminder(expands: expands, showsCane: true)
                .frame(width: min(420, max(280, size.width * 0.38)))
        }
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil)
    }

    @ViewBuilder
    private var faultBanner: some View {
        if let fault = watch.fault, !watch.loadFailed {
            TrellisBanner(text: fault) {
                Task { await watch.retry() }
            }
        }
    }

    private func emptyCard(expands: Bool) -> some View {
        VStack(spacing: TrellisRail.space(2)) {
            VStack(spacing: TrellisRail.space(2)) {
                Image(TrellisPlate.emptyList)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: TrellisRail.space(28), maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text("No vines planted.")
                    .trellisInk(.heading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Plant a goal on the garden. Contact and reset stay here.")
                    .font(TrellisFace.font(.body))
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil)
            TrellisCapsule(
                title: "Plant",
                fills: true,
                emphasized: true
            ) {
                showPlant = true
            }
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil, alignment: .leading)
        .trellisCard()
    }

    private func gardenBoard(expands: Bool) -> some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            deviceHeader
            caneFan(vines: watch.garden.vines, expands: expands)
            if let vine = watch.openVine {
                CaneBeadReadout(vine: vine)
            }
            pinchCopy
            pinchCapsule
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil, alignment: .leading)
        .background { boardFill }
        .clipShape(TrellisRail.cardShape)
        .background(.regularMaterial, in: TrellisRail.cardShape)
    }

    private func vineSummary(expands: Bool) -> some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            deviceHeader
            caneFan(vines: watch.garden.vines, expands: expands)
            Text("Hatched wood · dashed waiting. Beads sit on wood. Open a cane on Garden.")
                .font(TrellisFace.font(.caption))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil, alignment: .leading)
        .background { boardFill }
        .clipShape(TrellisRail.cardShape)
        .background(.regularMaterial, in: TrellisRail.cardShape)
    }

    private func pinchReminder(expands: Bool, showsCane: Bool) -> some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            pinchCopy
            if let vine = watch.openVine {
                HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(2)) {
                    figure(TrellisFigures.money(vine.leader.wood.amount), "Wood")
                    figure(TrellisFigures.money(vine.leader.flush.amount), "Waiting")
                    figure(TrellisFigures.money(vine.target), "Target")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(vine.name). Wood \(TrellisFigures.money(vine.leader.wood.amount)), waiting \(TrellisFigures.money(vine.leader.flush.amount)), target \(TrellisFigures.money(vine.target))"
                )
                CaneBeadReadout(vine: vine)
                if showsCane {
                    caneFan(vines: [vine], expands: expands)
                }
            }
            pinchCapsule
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: expands ? .infinity : nil, alignment: .leading)
        .trellisCard()
    }

    private var deviceHeader: some View {
        Button {
            watch.tab = .analytics
        } label: {
            HStack(alignment: .top, spacing: TrellisRail.space(1)) {
                VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
                    Text("On this device")
                        .trellisInk(.heading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(2)) {
                        figure(TrellisFigures.money(watch.garden.woodAmount), "Wood")
                        figure(TrellisFigures.money(watch.garden.flushAmount), "Waiting")
                        figure(TrellisFigures.count(watch.garden.nodeMarkCount), "Beads")
                        figure(TrellisFigures.count(watch.garden.vines.count), "Vines")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .padding(.top, TrellisRail.space(1))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(TrellisPressStyle(enabled: true))
        .accessibilityLabel(
            "Analytics, on this device, wood \(TrellisFigures.money(watch.garden.woodAmount)), waiting \(TrellisFigures.money(watch.garden.flushAmount)), \(TrellisFigures.count(watch.garden.nodeMarkCount)) beads, \(TrellisFigures.count(watch.garden.vines.count)) vines"
        )
        .accessibilityHint("Opens Analytics.")
    }

    private var pinchCopy: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            Text(watch.canPinchLeader ? "Pinch the leader" : "Pour, then pinch")
                .trellisInk(.heading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(watch.jobLine)
                .font(TrellisFace.font(.callout))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var pinchCapsule: some View {
        TrellisCapsule(
            title: watch.canPinchLeader ? "Pinch on Garden" : "Open Garden",
            artwork: TrellisPlate.controlFace,
            fills: true,
            emphasized: watch.canPinchLeader,
            hint: "Opens the garden so you can pinch the leader."
        ) {
            watch.tab = .garden
        }
    }

    private func caneFan(vines: [Vine], expands: Bool) -> some View {
        PalmetteFan(
            vines: vines,
            openID: watch.openVine?.id
        ) { vineID in
            Task { await watch.openOnGarden(vineID) }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: TrellisRail.space(14))
        .frame(maxHeight: expands ? .infinity : nil)
        .frame(height: expands ? nil : TrellisRail.space(20))
    }

    private var boardFill: some View {
        ZStack {
            TrellisInk.Palette.surface.opacity(0.35)
            Image(TrellisPlate.cardBackdrop)
                .resizable()
                .scaledToFill()
                .opacity(0.22)
                .clipped()
        }
        .accessibilityHidden(true)
    }

    private var houseCard: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            Text("Housekeeping")
                .trellisInk(.heading)
            Text("Everything stays on this device. There is no bank link.")
                .font(TrellisFace.font(.callout))
                .foregroundStyle(TrellisInk.Palette.ink)
            Link(destination: EspalierClient.contactURL) {
                HStack(spacing: TrellisRail.space(2)) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Contact Palmette")
                            .trellisInk(.body)
                        Text(EspalierClient.contactURL.absoluteString)
                            .font(TrellisFace.font(.caption))
                            .foregroundStyle(TrellisInk.Palette.ink)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(TrellisInk.Palette.ink)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, TrellisRail.space(2))
                .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
                .background(TrellisInk.Palette.surface)
                .clipShape(TrellisRail.chipShape)
                .overlay {
                    TrellisRail.chipShape.stroke(TrellisInk.Palette.ink.opacity(0.18), lineWidth: 1)
                }
                .contentShape(TrellisRail.chipShape)
            }
            .accessibilityLabel("Contact Palmette")
            .buttonStyle(TrellisPressStyle(enabled: true))
            TrellisCapsule(
                title: "Re-run onboarding",
                fills: true,
                enabled: !watch.isCommitting
            ) {
                Task { await watch.reopenOnboarding() }
            }
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .font(TrellisFace.font(.body))
                    .foregroundStyle(TrellisInk.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
                    .background(TrellisInk.Palette.background)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(TrellisPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Reset all data")
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .trellisCard()
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
