import SwiftUI

/// Role: NodeMark. Section 3.6 Analytics tab. Named for the live driver; body is the NodeMark ledger.
struct AnalyticsView: View {
    var watch: GardenWatch

    var body: some View {
        NodeMarkLedger(watch: watch)
    }
}

/// Role: NodeMark. Analytics of NodeMarks and ripe vines. Not a deposit list.
struct NodeMarkLedger: View {
    var watch: GardenWatch
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
                    headline: "Beads could not be read.",
                    line: watch.fault ?? "The garden started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.garden.nodeMarkCount == 0 {
                TrellisVacancy(
                    image: TrellisPlate.emptyList,
                    headline: "No node beads yet.",
                    line: "Pinch a leader so wood can write beads at each quarter of the target.",
                    actionTitle: "Open Garden"
                ) {
                    watch.tab = .garden
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TrellisInk.Palette.background.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TrellisInk.Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showTwist) {
            PinchThenNode(watch: watch, onClose: { showTwist = false })
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TrellisRail.space(2)) {
                job
                readout
                Button {
                    showTwist = true
                } label: {
                    HStack(spacing: TrellisRail.space(2)) {
                        Image(TrellisPlate.twistHero)
                            .resizable()
                            .scaledToFit()
                            .frame(width: TrellisRail.space(5), height: TrellisRail.space(5))
                            .padding(TrellisRail.space(1))
                            .background(TrellisInk.Palette.surface)
                            .clipShape(TrellisRail.chipShape)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Pinch, then a node")
                                .trellisInk(.heading)
                                .lineLimit(1)
                            Text("Waiting cash never beads. Pinch writes wood, then beads.")
                                .font(TrellisFace.font(.caption))
                                .foregroundStyle(TrellisInk.Palette.ink)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(TrellisInk.Palette.ink)
                            .accessibilityHidden(true)
                    }
                    .padding(TrellisRail.space(2))
                    .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
                    .trellisCard()
                    .contentShape(TrellisRail.cardShape)
                }
                .buttonStyle(TrellisPressStyle(enabled: true))
                .accessibilityLabel("Pinch, then a node")

                ForEach(watch.garden.vines) { vine in
                    vineButton(vine)
                }

                if let fault = watch.fault, !watch.loadFailed {
                    TrellisBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                }
            }
            .padding(.horizontal, TrellisRail.space(2))
            .padding(.top, TrellisRail.space(2))
            .padding(.bottom, TrellisRail.space(8))
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, TrellisRail.space(6), for: .scrollContent)
    }

    private var job: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            Text("Open a vine to pinch")
                .trellisInk(.trellis)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("Each bead is a quarter of that vine’s target, written only when you pinch. Tap a vine to open it on Garden.")
                .font(TrellisFace.font(.body))
                .foregroundStyle(TrellisInk.Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            Text(TrellisFigures.count(watch.garden.nodeMarkCount))
                .trellisInk(.trellis)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text("Node beads")
                .font(TrellisFace.font(.callout))
                .foregroundStyle(TrellisInk.Palette.ink)
            HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(3)) {
                figure(TrellisFigures.count(watch.garden.ripeVineCount), "Ripe vines")
                figure(TrellisFigures.count(watch.garden.vines.count), "Planted")
            }
        }
        .padding(TrellisRail.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Image(TrellisPlate.cardBackdrop)
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .clipped()
                .accessibilityHidden(true)
        }
        .clipShape(TrellisRail.cardShape)
        .background(.regularMaterial, in: TrellisRail.cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(TrellisFigures.count(watch.garden.nodeMarkCount)) node beads, \(TrellisFigures.count(watch.garden.ripeVineCount)) ripe vines, \(TrellisFigures.count(watch.garden.vines.count)) planted"
        )
    }

    private func vineButton(_ vine: Vine) -> some View {
        Button {
            Task { await watch.openOnGarden(vine.id) }
        } label: {
            HStack(alignment: .top, spacing: TrellisRail.space(1)) {
                VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
                    HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(1)) {
                        Text(vine.name)
                            .trellisInk(.heading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        if vine.isRipe {
                            Text("Ripe")
                                .font(TrellisFace.font(.callout))
                                .foregroundStyle(TrellisInk.Palette.ink)
                                .lineLimit(1)
                        }
                        Spacer(minLength: TrellisRail.space(1))
                        Text(TrellisFigures.percent(min(1, vine.progress)))
                            .font(TrellisFace.font(.figure))
                            .foregroundStyle(TrellisInk.Palette.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: TrellisRail.space(2)) {
                        figure(TrellisFigures.money(vine.leader.wood.amount), "Wood")
                        figure(TrellisFigures.money(vine.leader.flush.amount), "Waiting")
                        figure(TrellisFigures.money(vine.target), "Target")
                    }
                    CaneBeadReadout(vine: vine)
                    Text(vineCue(vine))
                        .font(TrellisFace.font(.callout))
                        .foregroundStyle(TrellisInk.Palette.ink)
                        .lineLimit(2)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .padding(.top, TrellisRail.space(1))
                    .accessibilityHidden(true)
            }
            .padding(TrellisRail.space(2))
            .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
            .trellisCard()
            .contentShape(TrellisRail.cardShape)
        }
        .buttonStyle(TrellisPressStyle(enabled: true))
        .accessibilityLabel(vineSpeak(vine))
        .accessibilityHint("Opens this vine on the garden.")
    }

    private func vineCue(_ vine: Vine) -> String {
        if vine.canPinchLeader {
            return "Open on Garden to pinch."
        }
        if vine.isRipe {
            return "Wood holds the target. Open on Garden."
        }
        return "Open on Garden to pour, then pinch."
    }

    private func vineSpeak(_ vine: Vine) -> String {
        let ripe = vine.isRipe ? " Ripe." : ""
        return "\(vine.name).\(ripe) Wood \(TrellisFigures.money(vine.leader.wood.amount)), waiting \(TrellisFigures.money(vine.leader.flush.amount)), target \(TrellisFigures.money(vine.target)). \(CaneBeadReadout.caption(vine.nodeMarks))"
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
}

/// Role: NodeMark. Quartile stations as beads and plain text. Never chip chrome.
struct CaneBeadReadout: View {
    var vine: Vine

    var body: some View {
        VStack(alignment: .leading, spacing: TrellisRail.space(1)) {
            HStack(spacing: 0) {
                ForEach(Array(CaneQuartile.allCases.enumerated()), id: \.element) { index, station in
                    Image(systemName: filled(station) ? "circle.fill" : "circle")
                        .font(TrellisFace.font(.caption).weight(.semibold))
                        .foregroundStyle(TrellisInk.Palette.ink.opacity(filled(station) ? 0.92 : 0.28))
                        .accessibilityHidden(true)
                    if index < CaneQuartile.allCases.count - 1 {
                        Rectangle()
                            .fill(TrellisInk.Palette.ink.opacity(0.18))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(minHeight: TrellisRail.space(2))
            Text(Self.caption(vine.nodeMarks))
                .font(TrellisFace.font(.caption))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func filled(_ station: CaneQuartile) -> Bool {
        vine.nodeMarks.contains { abs($0.quartile - station.rawValue) < 0.000_000_1 }
    }

    static func caption(_ marks: [NodeMark]) -> String {
        if marks.isEmpty {
            return "No beads. Waiting cash never writes one."
        }
        let parts = marks
            .sorted { $0.quartile < $1.quartile }
            .map { TrellisFigures.quartile($0.quartile) }
        return "Beads at \(parts.joined(separator: " · "))"
    }
}
