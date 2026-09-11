import Foundation

/// Role: Leader. The open cane: Flush (green, unpinched) beside Wood (lignified). pinchLeader folds Flush into Wood on the Vine, not here.
struct Leader: Equatable, Sendable {
    var flush: Flush
    var wood: Wood

    static let dormant = Leader(flush: .none, wood: .none)

    var canPinch: Bool { !flush.isEmpty }

    func pouring(_ amount: Double) throws -> Leader {
        Leader(flush: try flush.adding(amount), wood: wood)
    }

    func retracting(_ amount: Double) throws -> Leader {
        Leader(flush: try flush.peeling(amount), wood: wood)
    }

    func retractingFlush() -> Leader {
        Leader(flush: .none, wood: wood)
    }

    /// Moves every unit of Flush into Wood. NodeMarks are written by Vine using the vine's own target.
    func lignifying() -> Leader {
        guard canPinch else { return self }
        return Leader(flush: .none, wood: wood.absorbing(flush))
    }
}
