import Foundation

/// Role: NodeMark. A bead written only when pinchLeader carries Wood across a quartile of that vine's target.
struct NodeMark: Equatable, Sendable, Identifiable {
    var id: UUID
    var quartile: Double
    var woodAmount: Double
    var writtenUnix: Double
}
