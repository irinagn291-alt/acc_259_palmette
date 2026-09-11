import SwiftUI

/// Role: Vine. SF Pro via Font.system only. Six steps, none larger than 34pt, never below 12pt. Views never pick a raw font.
enum TrellisFace {
    enum Step: CaseIterable {
        case trellis
        case heading
        case body
        case callout
        case caption
        case figure

        var font: Font {
            switch self {
            case .trellis:
                .system(.title).weight(.semibold)
            case .heading:
                .system(.title3).weight(.semibold)
            case .body:
                .system(.body)
            case .callout:
                .system(.callout)
            case .caption:
                .system(.caption)
            case .figure:
                .system(.title2).weight(.semibold).monospacedDigit()
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }
}
