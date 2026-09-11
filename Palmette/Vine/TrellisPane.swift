import SwiftUI

/// Role: Vine. Garden home. Palmette trellis plus fused pour and pinch. Never a list of deposits.
struct TrellisPane: View {
    var watch: GardenWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pourDraft = ""
    @State private var showPlant = false
    @State private var showTwist = false
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            Group {
                if watch.isHauling {
                    ProgressView()
                        .tint(TrellisInk.Palette.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if watch.loadFailed {
                    TrellisVacancy(
                        image: TrellisPlate.emptyHome,
                        headline: "The garden could not be read.",
                        line: watch.fault ?? "The garden started empty.",
                        actionTitle: "Retry",
                        enabled: !watch.isCommitting
                    ) {
                        Task { await watch.retry() }
                    }
                } else if watch.isFreshGarden {
                    TrellisVacancy(
                        image: TrellisPlate.emptyHome,
                        headline: "The garden is empty.",
                        line: "Plant your first goal.",
                        actionTitle: "Plant",
                        enabled: !watch.isCommitting
                    ) {
                        showPlant = true
                    }
                } else if wide {
                    widePopulated(size: proxy.size)
                } else {
                    phonePopulated(height: proxy.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(TrellisInk.Palette.background.ignoresSafeArea())
        .navigationTitle("Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TrellisInk.Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                TrellisGlyphButton(
                    systemName: "info.circle",
                    label: "How pinch writes nodes"
                ) {
                    showTwist = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                TrellisGlyphButton(
                    systemName: "plus",
                    label: "Plant a vine",
                    enabled: !watch.isHauling && !watch.loadFailed
                ) {
                    showPlant = true
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { TrellisKeyboard.dismiss() }
                    .frame(minHeight: TrellisRail.tap)
            }
        }
        .sheet(isPresented: $showPlant) {
            PlantFold(watch: watch, onClose: { showPlant = false })
        }
        .sheet(isPresented: $showTwist) {
            PinchThenNode(watch: watch, onClose: { showTwist = false })
        }
        .sensoryFeedback(.success, trigger: watch.commitTick)
        .onChange(of: watch.pinchTick) { _, _ in
            flashSuccess()
        }
        .onDisappear {
            successTask?.cancel()
        }
        .overlay {
            if showSuccess {
                Image(TrellisPlate.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: TrellisRail.space(10), height: TrellisRail.space(10))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? TrellisRail.fade : TrellisRail.motion, value: showSuccess)
    }

    private func widePopulated(size: CGSize) -> some View {
        HStack(alignment: .top, spacing: TrellisRail.space(2)) {
            VStack(spacing: TrellisRail.space(1)) {
                header
                hero
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                vineChips
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ScrollView {
                LeaderDock(watch: watch, draft: $pourDraft, compact: false)
            }
            .scrollDismissesKeyboard(.immediately)
            .frame(width: min(400, size.width * 0.42))
        }
        .padding(.horizontal, TrellisRail.space(2))
        .padding(.bottom, TrellisRail.space(1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func phonePopulated(height: CGFloat) -> some View {
        let useScroll = typeSize.isAccessibilitySize
        let stack = VStack(spacing: TrellisRail.space(1)) {
            header
                .layoutPriority(1)
            hero
                .frame(maxWidth: .infinity, maxHeight: useScroll ? nil : .infinity)
                .frame(height: useScroll ? max(TrellisRail.space(18), height * 0.28) : nil)
                .layoutPriority(0)
            vineChips
                .layoutPriority(1)
            LeaderDock(watch: watch, draft: $pourDraft, compact: true)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.horizontal, TrellisRail.space(2))
        .padding(.bottom, TrellisRail.space(1))
        .frame(maxWidth: .infinity, maxHeight: useScroll ? nil : .infinity, alignment: .top)

        if useScroll {
            ScrollView {
                stack
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        } else {
            stack
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            Text(watch.jobTitle)
                .trellisInk(.trellis)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(watch.jobLine)
                .font(TrellisFace.font(.body))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Button {
                watch.tab = .analytics
            } label: {
                HStack(spacing: TrellisRail.space(2)) {
                    stripFigure(TrellisFigures.count(watch.garden.nodeMarkCount), "Beads")
                    stripFigure(TrellisFigures.count(watch.garden.ripeVineCount), "Ripe")
                    stripFigure(TrellisFigures.count(watch.garden.vines.count), "Vines")
                }
                .padding(.horizontal, TrellisRail.space(2))
                .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
                .trellisCard()
                .contentShape(TrellisRail.cardShape)
            }
            .buttonStyle(TrellisPressStyle(enabled: true))
            .accessibilityLabel(
                "Analytics, \(TrellisFigures.count(watch.garden.nodeMarkCount)) node beads, \(TrellisFigures.count(watch.garden.ripeVineCount)) ripe vines, \(TrellisFigures.count(watch.garden.vines.count)) vines"
            )
            if let fault = watch.fault, !watch.loadFailed {
                TrellisBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stripFigure(_ value: String, _ caption: String) -> some View {
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

    private var hero: some View {
        ZStack(alignment: .bottom) {
            PalmetteFan(
                vines: watch.garden.vines,
                openID: watch.openVine?.id
            ) { vineID in
                TrellisKeyboard.dismiss()
                Task { await watch.openVine(vineID) }
            }
            .padding(.bottom, watch.openVine == nil ? 0 : TrellisRail.space(9))
            .simultaneousGesture(
                TapGesture().onEnded { TrellisKeyboard.dismiss() }
            )
            if let vine = watch.openVine {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(2)) {
                        stripFigure(TrellisFigures.money(vine.leader.wood.amount), "Wood")
                        stripFigure(TrellisFigures.money(vine.leader.flush.amount), "Waiting")
                        stripFigure(TrellisFigures.money(vine.target), "Target")
                    }
                    Text("Hatched wood · dashed waiting. Beads sit on wood.")
                        .font(TrellisFace.font(.caption))
                        .foregroundStyle(TrellisInk.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, TrellisRail.space(1))
                }
                .padding(.horizontal, TrellisRail.space(2))
                .padding(.vertical, TrellisRail.space(1))
                .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(vine.name). Hatched wood \(TrellisFigures.money(vine.leader.wood.amount)) of \(TrellisFigures.money(vine.target)). Dashed waiting \(TrellisFigures.money(vine.leader.flush.amount))."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                TrellisInk.Palette.surface
                Image(TrellisPlate.cardBackdrop)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.28)
                    .clipped()
            }
            .accessibilityHidden(true)
        }
        .clipShape(TrellisRail.cardShape)
        .background(.regularMaterial, in: TrellisRail.cardShape)
        .animation(reduceMotion ? TrellisRail.fade : TrellisRail.motion, value: watch.openVine?.leader.flush.amount)
        .animation(reduceMotion ? TrellisRail.fade : TrellisRail.motion, value: watch.openVine?.leader.wood.amount)
        .animation(reduceMotion ? TrellisRail.fade : TrellisRail.motion, value: watch.garden.nodeMarkCount)
        .accessibilityElement(children: .contain)
    }

    private var vineChips: some View {
        TrellisChipFlow(spacing: TrellisRail.space(1)) {
            ForEach(watch.garden.vines) { vine in
                TrellisChip(
                    title: vine.name,
                    selected: vine.id == watch.openVine?.id
                ) {
                    TrellisKeyboard.dismiss()
                    Task { await watch.openVine(vine.id) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Vines")
    }

    private func flashSuccess() {
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}
