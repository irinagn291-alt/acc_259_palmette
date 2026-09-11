import Foundation

/// Role: NodeMark. Quartile crossings of one vine's target: 0.25, 0.5, 0.75, 1.0. Unpinched Flush never reaches these.
enum CaneQuartile: Double, Equatable, Hashable, Sendable, CaseIterable {
    case quarter = 0.25
    case half = 0.5
    case threeQuarter = 0.75
    case ripe = 1.0

    static let milestoneRatios: [Double] = allCases.map(\.rawValue)

    static func parse(_ value: Double) -> CaneQuartile? {
        allCases.first { abs($0.rawValue - value) < 0.000_000_1 }
    }

    /// Quartiles Wood newly reaches on this vine's target. beforeWood / target is exclusive; afterWood / target is inclusive.
    static func newlyReached(beforeWood: Double, afterWood: Double, target: Double) -> [CaneQuartile] {
        guard target.isFinite, target > 0,
              beforeWood.isFinite, afterWood.isFinite else { return [] }
        let before = beforeWood / target
        let after = afterWood / target
        return allCases.filter { quartile in
            before < quartile.rawValue && after >= quartile.rawValue
        }
    }
}
