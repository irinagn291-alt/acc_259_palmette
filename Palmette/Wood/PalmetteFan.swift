import SwiftUI

/// Role: Wood. Layout math for the palmette fan. vineSeed leans and bows each cane. Not a domain type.
enum PalmetteFanLayout {
    struct Cane: Equatable {
        var bole: CGPoint
        var targetTip: CGPoint
        var control: CGPoint
        var woodT: CGFloat
        var fillT: CGFloat

        var woodTip: CGPoint {
            PalmetteFanLayout.point(t: woodT, start: bole, control: control, end: targetTip)
        }

        var flushTip: CGPoint {
            PalmetteFanLayout.point(t: fillT, start: bole, control: control, end: targetTip)
        }

        var tip: CGPoint { flushTip }
    }

    static func headingRadians(seed: Int, index: Int, count: Int) -> Double {
        let span = Double.pi * 0.78
        let wobble = Double((seed % 13) - 6) * 0.018
        if count <= 1 { return wobble }
        let start = -span / 2
        let step = span / Double(count - 1)
        return start + step * Double(index) + wobble
    }

    static func bow(seed: Int) -> CGFloat {
        CGFloat((seed % 19) - 9) / 28.0
    }

    static func cane(vine: Vine, index: Int, count: Int, size: CGSize) -> Cane {
        let padX = max(22, min(size.width * 0.08, 36))
        let padY = max(18, min(size.height * 0.07, 32))
        let bole = CGPoint(x: size.width * 0.5, y: size.height - padY)
        let heading = headingRadians(seed: vine.vineSeed, index: index, count: count)
        let xReach = max(24, size.width * 0.5 - padX)
        let yReach = max(24, bole.y - padY)
        let targetTip = CGPoint(
            x: bole.x + CGFloat(sin(heading)) * xReach,
            y: bole.y - CGFloat(cos(heading)) * yReach
        )
        let bowAmount = bow(seed: vine.vineSeed)
        let control = controlPoint(from: bole, to: targetTip, bow: bowAmount)
        return Cane(
            bole: bole,
            targetTip: targetTip,
            control: control,
            woodT: CGFloat(min(1, max(0, vine.progress))),
            fillT: CGFloat(min(1, max(0, vine.caneFill)))
        )
    }

    static func point(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let u = max(0, min(1, t))
        let inv = 1 - u
        return CGPoint(
            x: inv * inv * start.x + 2 * inv * u * control.x + u * u * end.x,
            y: inv * inv * start.y + 2 * inv * u * control.y + u * u * end.y
        )
    }

    private static func controlPoint(from start: CGPoint, to end: CGPoint, bow: CGFloat) -> CGPoint {
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let dx = end.x - start.x
        let dy = end.y - start.y
        return CGPoint(x: mid.x + (-dy) * bow, y: mid.y + dx * bow)
    }
}

/// Role: Wood. The only custom-drawn surface: fan-trained glass canes from vineSeed, Wood, and Flush.
struct PalmetteFan: View {
    var vines: [Vine]
    var openID: UUID?
    var onOpen: (UUID) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    PalmetteFanDraw.render(vines: vines, openID: openID, in: &context, size: size)
                }
                .accessibilityHidden(true)
                ForEach(Array(vines.enumerated()), id: \.element.id) { index, vine in
                    let layout = PalmetteFanLayout.cane(
                        vine: vine,
                        index: index,
                        count: vines.count,
                        size: proxy.size
                    )
                    Button {
                        onOpen(vine.id)
                    } label: {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: TrellisRail.tap, height: TrellisRail.tap)
                            .contentShape(Circle())
                    }
                    .position(layout.tip)
                    .buttonStyle(TrellisPressStyle(enabled: true))
                    .accessibilityLabel(Self.speak(vine, open: vine.id == openID))
                    .accessibilityHint("Opens this vine on the garden.")
                    .accessibilityAddTraits(vine.id == openID ? AccessibilityTraits.isSelected : AccessibilityTraits())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    static func speak(_ vine: Vine, open: Bool) -> String {
        let wood = TrellisFigures.money(vine.leader.wood.amount)
        let waiting = TrellisFigures.money(vine.leader.flush.amount)
        let beads = TrellisFigures.count(vine.nodeMarks.count)
        let openWord = open ? "Open vine. " : ""
        let ripe = vine.isRipe ? " Ripe." : ""
        return "\(openWord)\(vine.name). Hatched wood \(wood) of \(TrellisFigures.money(vine.target)). Dashed waiting \(waiting). \(beads) node beads.\(ripe)"
    }
}

enum PalmetteFanDraw {
    static func render(vines: [Vine], openID: UUID?, in context: inout GraphicsContext, size: CGSize) {
        drawWires(&context, size: size)
        drawBole(&context, size: size)
        for (index, vine) in vines.enumerated() {
            let layout = PalmetteFanLayout.cane(vine: vine, index: index, count: vines.count, size: size)
            drawCane(vine: vine, layout: layout, open: vine.id == openID, size: size, in: &context)
        }
    }

    private static func drawWires(_ context: inout GraphicsContext, size: CGSize) {
        let count = max(3, Int(size.height / 84))
        var rails = Path()
        for step in 1...count {
            let y = size.height * CGFloat(step) / CGFloat(count + 1)
            rails.move(to: CGPoint(x: size.width * 0.06, y: y))
            rails.addLine(to: CGPoint(x: size.width * 0.94, y: y))
        }
        context.stroke(
            rails,
            with: .color(TrellisInk.Palette.ink.opacity(0.12)),
            style: StrokeStyle(lineWidth: 1, lineCap: .round)
        )
    }

    private static func drawBole(_ context: inout GraphicsContext, size: CGSize) {
        let padY = max(18, min(size.height * 0.07, 32))
        let radius = max(10, max(size.width, size.height) * 0.014)
        let bole = CGRect(
            x: size.width * 0.5 - radius,
            y: size.height - padY - radius * 0.35,
            width: radius * 2,
            height: radius * 1.4
        )
        context.fill(
            Path(ellipseIn: bole),
            with: .color(TrellisInk.Palette.ink.opacity(0.35))
        )
    }

    private static func drawCane(
        vine: Vine,
        layout: PalmetteFanLayout.Cane,
        open: Bool,
        size: CGSize,
        in context: inout GraphicsContext
    ) {
        let metric = max(size.width, size.height)
        let width: CGFloat = max(open ? 11 : 7, metric * (open ? 0.018 : 0.012))

        var trained = Path()
        trained.move(to: layout.bole)
        trained.addQuadCurve(to: layout.targetTip, control: layout.control)
        context.stroke(
            trained,
            with: .color(TrellisInk.Palette.ink.opacity(open ? 0.26 : 0.14)),
            style: StrokeStyle(lineWidth: max(2.5, width * 0.42), lineCap: .round, lineJoin: .round)
        )

        if layout.fillT > 0 {
            var flush = Path()
            flush.move(to: layout.bole)
            flush.addQuadCurve(to: layout.flushTip, control: layout.control)
            context.stroke(
                flush,
                with: .color(TrellisInk.Palette.accent.opacity(open ? 0.88 : 0.5)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: [12, 7])
            )
        }

        if layout.woodT > 0 {
            var wood = Path()
            wood.move(to: layout.bole)
            wood.addQuadCurve(to: layout.woodTip, control: layout.control)
            context.stroke(
                wood,
                with: .color(TrellisInk.Palette.ink.opacity(open ? 0.9 : 0.64)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
            drawHatch(layout: layout, open: open, size: size, in: &context)
        }

        for mark in vine.nodeMarks {
            let t = CGFloat(min(1, max(0, mark.quartile)))
            let bead = PalmetteFanLayout.point(
                t: t,
                start: layout.bole,
                control: layout.control,
                end: layout.targetTip
            )
            let radius: CGFloat = max(open ? 7 : 5, metric * (open ? 0.012 : 0.009))
            let rect = CGRect(x: bead.x - radius, y: bead.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(TrellisInk.Palette.ink.opacity(0.92)))
            context.stroke(
                Path(ellipseIn: rect.insetBy(dx: 1, dy: 1)),
                with: .color(TrellisInk.Palette.surface.opacity(0.9)),
                lineWidth: 1.5
            )
        }
    }

    private static func drawHatch(
        layout: PalmetteFanLayout.Cane,
        open: Bool,
        size: CGSize,
        in context: inout GraphicsContext
    ) {
        let span = hypot(layout.woodTip.x - layout.bole.x, layout.woodTip.y - layout.bole.y)
        let ticks = max(8, Int(span / 22))
        let hatch: CGFloat = max(open ? 7 : 5, max(size.width, size.height) * 0.012)
        for step in 1..<ticks {
            let t = layout.woodT * CGFloat(step) / CGFloat(ticks)
            guard t > 0.04, t <= layout.woodT else { continue }
            let point = PalmetteFanLayout.point(
                t: t,
                start: layout.bole,
                control: layout.control,
                end: layout.targetTip
            )
            let before = PalmetteFanLayout.point(
                t: max(0, t - 0.03),
                start: layout.bole,
                control: layout.control,
                end: layout.targetTip
            )
            let after = PalmetteFanLayout.point(
                t: min(1, t + 0.03),
                start: layout.bole,
                control: layout.control,
                end: layout.targetTip
            )
            let dx = after.x - before.x
            let dy = after.y - before.y
            let length = max(0.001, hypot(dx, dy))
            let nx = -dy / length
            let ny = dx / length
            var tick = Path()
            tick.move(to: CGPoint(x: point.x - nx * hatch, y: point.y - ny * hatch))
            tick.addLine(to: CGPoint(x: point.x + nx * hatch, y: point.y + ny * hatch))
            context.stroke(
                tick,
                with: .color(TrellisInk.Palette.surface.opacity(open ? 0.95 : 0.7)),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        }
    }
}
