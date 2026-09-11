import Foundation

/// Role: Wood. Lignified savings. Only pinchLeader moves Flush into Wood; progress is wood divided by the vine's target.
struct Wood: Equatable, Sendable {
    var amount: Double

    static let none = Wood(amount: 0)

    func absorbing(_ flush: Flush) -> Wood {
        Wood(amount: amount + max(0, flush.amount))
    }
}
