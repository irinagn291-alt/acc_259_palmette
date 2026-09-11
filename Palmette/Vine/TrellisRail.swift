import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Vine. Spacing, radii, motion, and primary Capsule chrome. Cards use Material, never a second elevation.
enum TrellisRail {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 24
    static let chipRadius: CGFloat = 14
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }
}

/// Role: Vine. Dismisses the decimal pad. Scroll and Done also resign.
enum TrellisKeyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

/// Role: Vine. Pressed scale. Reduce Motion fades. Disabled is faded, not identical.
struct TrellisPressStyle: ButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        TrellisPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct TrellisPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled ? 0.97 : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(reduceMotion ? TrellisRail.fade : TrellisRail.motion, value: configuration.isPressed)
    }
}

extension View {
    func trellisInk(_ step: TrellisFace.Step) -> some View {
        font(TrellisFace.font(step))
            .foregroundStyle(TrellisInk.Palette.ink)
    }

    func trellisCard() -> some View {
        background(.regularMaterial, in: TrellisRail.cardShape)
    }

    func trellisChipFill() -> some View {
        background(.thinMaterial, in: TrellisRail.chipShape)
    }
}

/// Role: Vine. Primary CTA: filled Capsule inside tinted-glass Material. The fill is the target.
struct TrellisCapsule: View {
    var title: String
    var detail: String? = nil
    var artwork: String? = nil
    var fills: Bool = true
    var emphasized: Bool = false
    var enabled: Bool = true
    var busy: Bool = false
    var hint: String? = nil
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            HStack(spacing: TrellisRail.space(2)) {
                if let artwork {
                    Image(artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: TrellisRail.space(3), height: TrellisRail.space(3))
                        .padding(TrellisRail.space(1))
                        .background(TrellisInk.Palette.surface)
                        .clipShape(TrellisRail.chipShape)
                        .accessibilityHidden(true)
                }
                VStack(spacing: 0) {
                    Text(title)
                        .font(TrellisFace.font(.heading))
                        .foregroundStyle(emphasized && active ? TrellisInk.Palette.surface : TrellisInk.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail)
                            .font(TrellisFace.font(.caption))
                            .foregroundStyle(emphasized && active ? TrellisInk.Palette.surface : TrellisInk.Palette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: fills ? .infinity : nil)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, TrellisRail.space(2))
            .padding(.vertical, TrellisRail.space(1))
            .frame(maxWidth: fills ? .infinity : nil, minHeight: TrellisRail.tap)
            .background(emphasized && active ? TrellisInk.Palette.accent : TrellisInk.Palette.surface)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(
                    emphasized && active ? TrellisInk.Palette.accent : TrellisInk.Palette.ink.opacity(0.22),
                    lineWidth: emphasized && active ? 0 : 1
                )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(TrellisPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }
}

/// Role: Vine. Recoverable fault with a retry control.
struct TrellisBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: TrellisRail.space(1)) {
            Text(text)
                .font(TrellisFace.font(.callout))
                .foregroundStyle(TrellisInk.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(TrellisFace.font(.callout).weight(.semibold))
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .frame(minWidth: TrellisRail.tap, minHeight: TrellisRail.tap)
                    .padding(.horizontal, TrellisRail.space(1))
                    .background(TrellisInk.Palette.surface)
                    .clipShape(TrellisRail.chipShape)
                    .contentShape(TrellisRail.chipShape)
            }
            .buttonStyle(TrellisPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, TrellisRail.space(2))
        .padding(.vertical, TrellisRail.space(1))
        .frame(maxWidth: .infinity, minHeight: TrellisRail.tap, alignment: .leading)
        .trellisCard()
    }
}

/// Role: Vine. Sheet header with a dismiss that always works.
struct TrellisSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: TrellisRail.space(1)) {
            Text(title)
                .trellisInk(.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(TrellisFace.font(.body).weight(.semibold))
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .frame(width: TrellisRail.tap, height: TrellisRail.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(TrellisPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
    }
}

/// Role: Vine. Icon control. SF Symbol is the affordance, not the brand.
struct TrellisGlyphButton: View {
    var systemName: String
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(TrellisFace.font(.body).weight(.semibold))
                .foregroundStyle(TrellisInk.Palette.ink)
                .frame(width: TrellisRail.tap, height: TrellisRail.tap)
                .trellisChipFill()
                .contentShape(TrellisRail.chipShape)
        }
        .buttonStyle(TrellisPressStyle(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Role: Vine. Full-page empty or error. Art, headline, line, bottom Capsule CTA.
struct TrellisVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: TrellisRail.space(2)) {
            VStack(spacing: TrellisRail.space(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: TrellisRail.space(28), height: TrellisRail.space(28))
                    .accessibilityHidden(true)
                Text(headline)
                    .trellisInk(.heading)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(line)
                    .font(TrellisFace.font(.body))
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            TrellisCapsule(
                title: actionTitle,
                fills: true,
                emphasized: true,
                enabled: enabled,
                action: action
            )
        }
        .padding(.horizontal, TrellisRail.space(2))
        .padding(.bottom, TrellisRail.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TrellisInk.Palette.background)
    }
}

/// Role: Vine. Pill chip. 14 pt radius only. Selected uses a mark, not colour alone.
struct TrellisChip: View {
    var title: String
    var selected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) {
                label
            }
            .buttonStyle(TrellisPressStyle(enabled: true))
            .accessibilityLabel(title)
            .accessibilityValue(selected ? "Selected" : "Not selected")
        } else {
            label
                .accessibilityHidden(false)
        }
    }

    private var label: some View {
        HStack(spacing: TrellisRail.space(1)) {
            if selected {
                Image(systemName: "checkmark")
                    .font(TrellisFace.font(.caption).weight(.semibold))
                    .foregroundStyle(TrellisInk.Palette.ink)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(TrellisFace.font(.caption).weight(.semibold))
                .foregroundStyle(TrellisInk.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, TrellisRail.space(2))
        .frame(minWidth: TrellisRail.tap, minHeight: TrellisRail.tap)
        .trellisChipFill()
        .overlay {
            TrellisRail.chipShape.stroke(
                selected ? TrellisInk.Palette.accent : TrellisInk.Palette.ink.opacity(0.18),
                lineWidth: selected ? 2 : 1
            )
        }
        .contentShape(TrellisRail.chipShape)
    }
}

/// Role: Vine. Wraps chips so every vine name stays on the row, including the open one.
struct TrellisChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        packed(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let packed = packed(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (index, subview) in subviews.enumerated() {
            let frame = packed.frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func packed(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let limit = proposal.width ?? .infinity
        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let fitting = subview.sizeThatFits(.unspecified)
            let width: CGFloat
            if limit.isFinite {
                width = min(fitting.width, max(0, limit))
            } else {
                width = fitting.width
            }
            let height = max(fitting.height, TrellisRail.tap)
            if x > 0, limit.isFinite, x + width > limit {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: width, height: height))
            rowHeight = max(rowHeight, height)
            x += width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }
        let totalHeight = subviews.isEmpty ? 0 : y + rowHeight
        let totalWidth = limit.isFinite ? limit : usedWidth
        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}
